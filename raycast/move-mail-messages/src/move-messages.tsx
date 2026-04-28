import { Action, ActionPanel, closeMainWindow, Icon, List, showToast, Toast } from "@raycast/api";
import { useCachedPromise, usePromise } from "@raycast/utils";
import { runAppleScript } from "run-applescript";

type Mailbox = {
  account: string;
  mailbox: string;
  path: string;
  label: string;
  specialUse?: string;
};

type RawMailbox = {
  index: string;
  mailbox: string;
  parentIndex: string;
};

const SPECIAL_MAILBOX_DISPLAY_NAMES: Record<string, string> = {
  INBOX: "Inbox",
};

function getDisplayMailboxName(name: string): string {
  return SPECIAL_MAILBOX_DISPLAY_NAMES[name] ?? name;
}

function getSpecialMailboxUse(path: string): string | undefined {
  if (path === "INBOX") {
    return "inbox";
  }

  return undefined;
}

async function getSelectedAccount(): Promise<string | null> {
  const script = `
tell application "Mail"
	set theSelection to selection
	
	if (count of theSelection) is 0 then
		return ""
	end if
	
	set selectedAccount to name of account of mailbox of item 1 of theSelection
	
	repeat with theMail in theSelection
		if (name of account of mailbox of theMail) is not selectedAccount then
			error "Please select messages from a single account."
		end if
	end repeat
	
	return selectedAccount
end tell
`;

  return (await runAppleScript(script)) || null;
}

async function getMailboxes(account: string): Promise<Mailbox[]> {
  const script = `
tell application "Mail"
	set targetAccount to missing value
	
	repeat with acct in every account
		if name of acct is "${escapeAppleScriptString(account)}" then
			set targetAccount to acct
			exit repeat
		end if
	end repeat
	
	if targetAccount is missing value then
		error "Could not find the selected account."
	end if
	
	set mailboxJsonItems to {}
	set allMailboxes to every mailbox of targetAccount
	
	repeat with mailboxIndex from 1 to (count of allMailboxes)
		set mb to item mailboxIndex of allMailboxes
		set mbName to name of mb
		set parentIndex to ""
		
		try
			set parentMailbox to mailbox of mb
			if parentMailbox is not missing value then
				set parentIndex to (my indexOfMailbox(parentMailbox, allMailboxes)) as text
			end if
		on error
			set parentIndex to ""
		end try
		
		set end of mailboxJsonItems to "{\\"index\\":\\"" & mailboxIndex & "\\",\\"mailbox\\":\\"" & my escapeJson(mbName) & "\\",\\"parentIndex\\":\\"" & my escapeJson(parentIndex) & "\\"}"
	end repeat
	
	return "[" & my joinList(mailboxJsonItems, ",") & "]"
end tell

on indexOfMailbox(targetMailbox, mailboxList)
	repeat with mailboxIndex from 1 to (count of mailboxList)
		if item mailboxIndex of mailboxList is targetMailbox then
			return mailboxIndex
		end if
	end repeat
	
	return ""
end indexOfMailbox

on joinList(theList, delimiterText)
	if (count of theList) is 0 then
		return ""
	end if
	
	set previousDelimiters to AppleScript's text item delimiters
	set AppleScript's text item delimiters to delimiterText
	set joinedText to theList as text
	set AppleScript's text item delimiters to previousDelimiters
	return joinedText
end joinList

on escapeJson(t)
	set quoteChar to ASCII character 34
	set t to my replaceText("\\\\", "\\\\\\\\", t)
	set t to my replaceText(quoteChar, "\\\\" & quoteChar, t)
	return t
end escapeJson

on replaceText(findText, replaceText, sourceText)
	set AppleScript's text item delimiters to findText
	set textItems to text items of sourceText
	set AppleScript's text item delimiters to replaceText
	set newText to textItems as text
	set AppleScript's text item delimiters to ""
	return newText
end replaceText
`;

  const result = await runAppleScript(script);
  const rawMailboxes = (JSON.parse(result) as RawMailbox[]).map((mailbox) => ({
    ...mailbox,
    parentIndex: mailbox.parentIndex || "",
  }));
  const mailboxesByIndex = new Map(rawMailboxes.map((mailbox) => [mailbox.index, mailbox]));
  const pathsByIndex = new Map<string, string>();

  function getMailboxPath(mailbox: RawMailbox, visiting = new Set<string>()): string {
    const cachedPath = pathsByIndex.get(mailbox.index);
    if (cachedPath) {
      return cachedPath;
    }

    if (visiting.has(mailbox.index)) {
      return mailbox.mailbox;
    }

    visiting.add(mailbox.index);
    const parentMailbox = mailbox.parentIndex ? mailboxesByIndex.get(mailbox.parentIndex) : undefined;
    const path = parentMailbox ? `${getMailboxPath(parentMailbox, visiting)} / ${mailbox.mailbox}` : mailbox.mailbox;
    visiting.delete(mailbox.index);
    pathsByIndex.set(mailbox.index, path);
    return path;
  }

  return rawMailboxes
    .map((mailbox) => {
      const path = getMailboxPath(mailbox);
      const displayPath = path
        .split(" / ")
        .map((pathPart) => getDisplayMailboxName(pathPart))
        .join(" / ");

      return {
        account,
        mailbox: getDisplayMailboxName(mailbox.mailbox),
        path,
        label: `${account} → ${displayPath}`,
        specialUse: getSpecialMailboxUse(path),
      };
    })
    .sort((a, b) => a.label.localeCompare(b.label));
}

function escapeAppleScriptString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function moveSelectedMessages(account: string, mailboxPath: string, specialUse?: string) {
  const script = `
tell application "Mail"
	set theSelection to selection
	
	if (count of theSelection) is 0 then
		error "Please select at least one email in Mail."
	end if
	
	set targetMailbox to missing value
	set usesGmail to false
	set shouldArchiveAfterMove to false
	
	repeat with acct in every account
		if name of acct is "${escapeAppleScriptString(account)}" then
			set usesGmail to my accountLooksLikeGmail(acct)
			if "${escapeAppleScriptString(specialUse ?? "")}" is "inbox" then
				set targetMailbox to first mailbox of acct whose name is "INBOX"
			else
				repeat with mb in every mailbox of acct
					if my mailboxPath(mb) is "${escapeAppleScriptString(mailboxPath)}" then
						set targetMailbox to mb
						exit repeat
					end if
				end repeat
			end if
			exit repeat
		end if
	end repeat

	set shouldArchiveAfterMove to usesGmail and "${escapeAppleScriptString(specialUse ?? "")}" is not "inbox"
	
	if targetMailbox is missing value then
		error "Could not find target mailbox."
	end if
	
	repeat with theMail in theSelection
		move theMail to targetMailbox
	end repeat
	
	set selectionStillPresent to (count of selection) is greater than 0
	
	if shouldArchiveAfterMove then
		activate
	end if
end tell

if shouldArchiveAfterMove and selectionStillPresent then
	tell application "System Events"
		tell process "Mail"
			set archiveMenuItem to menu item "Archive" of menu 1 of menu bar item "Message" of menu bar 1
			if enabled of archiveMenuItem then
				click archiveMenuItem
			end if
		end tell
	end tell
end if

on accountLooksLikeGmail(theAccount)
	try
		set accountName to name of theAccount
		set accountId to id of theAccount
		return (accountName contains "gmail") or (accountName contains "Gmail") or (accountName contains "google") or (accountName contains "Google") or (accountId contains "gmail") or (accountId contains "Gmail") or (accountId contains "google") or (accountId contains "Google")
	on error
		return false
	end try
end accountLooksLikeGmail

on mailboxPath(theMailbox)
	set pathParts to {name of theMailbox}
	set currentMailbox to theMailbox
	
	repeat
		try
			set parentMailbox to mailbox of currentMailbox
		on error
			exit repeat
		end try
		
		if parentMailbox is missing value then
			exit repeat
		end if
		
		set beginning of pathParts to name of parentMailbox
		set currentMailbox to parentMailbox
	end repeat
	
	set AppleScript's text item delimiters to " / "
	set pathText to pathParts as text
	set AppleScript's text item delimiters to ""
	return pathText
end mailboxPath
`;

  await runAppleScript(script);
}

export default function Command() {
  const { data: selectedAccount, isLoading: isLoadingAccount, error: accountError } = usePromise(getSelectedAccount);
  const {
    data: cachedMailboxes,
    isLoading: isLoadingMailboxes,
    error: mailboxError,
  } = useCachedPromise(getMailboxes, selectedAccount ? [selectedAccount] : [], {
    execute: selectedAccount !== undefined && selectedAccount !== null,
    onError: () => undefined,
  });

  const mailboxes = cachedMailboxes ?? [];
  const isLoading =
    isLoadingAccount || (selectedAccount !== undefined && selectedAccount !== null && isLoadingMailboxes);
  const hasMailboxError = mailboxError instanceof Error && mailboxes.length === 0;
  const emptyViewTitle =
    accountError instanceof Error || hasMailboxError
      ? "Can't Show Mailboxes"
      : selectedAccount === null
        ? "Select Mail Messages"
        : "No Mailboxes Found";
  const emptyViewDescription =
    accountError instanceof Error
      ? accountError.message
      : hasMailboxError
        ? mailboxError.message
        : selectedAccount === null
          ? "Select one or more messages in Mail to show mailboxes from that account."
          : undefined;

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search mailboxes..." isShowingDetail={false}>
      {!isLoading && mailboxes.length === 0 ? (
        <List.EmptyView title={emptyViewTitle ?? "No Mailboxes Found"} description={emptyViewDescription} />
      ) : null}
      {mailboxes.map((item) => (
        <List.Item
          key={`${item.account}::${item.path}`}
          title={item.mailbox}
          accessories={[{ text: item.label }]}
          icon={Icon.Folder}
          actions={
            <ActionPanel>
              <Action
                title="Move Selected Mail Here"
                onAction={async () => {
                  try {
                    await closeMainWindow();
                    await moveSelectedMessages(item.account, item.path, item.specialUse);
                    await showToast({
                      style: Toast.Style.Success,
                      title: "Mail moved",
                      message: item.label,
                    });
                  } catch (error) {
                    await showToast({
                      style: Toast.Style.Failure,
                      title: "Failed to move mail",
                      message: error instanceof Error ? error.message : String(error),
                    });
                  }
                }}
              />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}
