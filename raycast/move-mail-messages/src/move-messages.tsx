import { Action, ActionPanel, closeMainWindow, Icon, List, showToast, Toast } from "@raycast/api";
import { usePromise } from "@raycast/utils";
import { runAppleScript } from "run-applescript";

type Mailbox = {
  account: string;
  mailbox: string;
  label: string;
};

type MailboxState = {
  mailboxes: Mailbox[];
  emptyViewTitle?: string;
  emptyViewDescription?: string;
};

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

  const result = await runAppleScript(script);
  return result || null;
}

async function getMailboxes(account: string): Promise<Mailbox[]> {
  const script = `
tell application "Mail"
	set json to "["
	set firstItem to true
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
	
	set acctName to name of targetAccount
	
	repeat with mb in every mailbox of targetAccount
		set mbName to name of mb
		set labelText to acctName & " → " & mbName
		
		set itemJson to "{\\"account\\":\\"" & my escapeJson(acctName) & "\\",\\"mailbox\\":\\"" & my escapeJson(mbName) & "\\",\\"label\\":\\"" & my escapeJson(labelText) & "\\"}"
		
		if firstItem then
			set json to json & itemJson
			set firstItem to false
		else
			set json to json & "," & itemJson
		end if
	end repeat
	
	set json to json & "]"
	return json
end tell

on escapeJson(t)
	set t to my replaceText("\\\\", "\\\\\\\\", t)
	set t to my replaceText("\\"", "\\\\\\"", t)
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
  const parsed = JSON.parse(result) as Mailbox[];
  return parsed.sort((a, b) => a.label.localeCompare(b.label));
}

async function getMailboxState(): Promise<MailboxState> {
  const account = await getSelectedAccount();

  if (!account) {
    return {
      mailboxes: [],
      emptyViewTitle: "Select Mail Messages",
      emptyViewDescription: "Select one or more messages in Mail to show mailboxes from that account.",
    };
  }

  return {
    mailboxes: await getMailboxes(account),
  };
}

function escapeAppleScriptString(value: string): string {
  return value.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

async function moveSelectedMessages(account: string, mailbox: string) {
  const script = `
tell application "Mail"
	set theSelection to selection
	
	if (count of theSelection) is 0 then
		error "Please select at least one email in Mail."
	end if
	
	set targetMailbox to missing value
	
	repeat with acct in every account
		if name of acct is "${escapeAppleScriptString(account)}" then
			repeat with mb in every mailbox of acct
				if name of mb is "${escapeAppleScriptString(mailbox)}" then
					set targetMailbox to mb
					exit repeat
				end if
			end repeat
			exit repeat
		end if
	end repeat
	
	if targetMailbox is missing value then
		error "Could not find target mailbox."
	end if
	
	repeat with theMail in theSelection
		move theMail to targetMailbox
	end repeat
end tell
`;
  await runAppleScript(script);
}

export default function Command() {
  const { data, isLoading, error } = usePromise(getMailboxState);
  const mailboxes = data?.mailboxes ?? [];
  const emptyViewTitle = error instanceof Error ? "Can't Show Mailboxes" : data?.emptyViewTitle;
  const emptyViewDescription = error instanceof Error ? error.message : data?.emptyViewDescription;

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search mailboxes..." isShowingDetail={false}>
      {!isLoading && mailboxes.length === 0 ? (
        <List.EmptyView title={emptyViewTitle ?? "No Mailboxes Found"} description={emptyViewDescription} />
      ) : null}
      {mailboxes.map((item) => (
        <List.Item
          key={`${item.account}::${item.mailbox}`}
          title={item.mailbox}
          subtitle={item.account}
          accessories={[{ text: item.label }]}
          icon={Icon.Folder}
          actions={
            <ActionPanel>
              <Action
                title="Move Selected Mail Here"
                onAction={async () => {
                  try {
                    await closeMainWindow();
                    await moveSelectedMessages(item.account, item.mailbox);
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
