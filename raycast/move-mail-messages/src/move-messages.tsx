import { Action, ActionPanel, closeMainWindow, Icon, List, showToast, Toast } from "@raycast/api";
import { usePromise } from "@raycast/utils";
import { runAppleScript } from "run-applescript";

type Mailbox = {
  account: string;
  mailbox: string;
  label: string;
};

async function getMailboxes(): Promise<Mailbox[]> {
  const script = `
tell application "Mail"
	set json to "["
	set firstItem to true
	
	repeat with acct in every account
		set acctName to name of acct
		
		repeat with mb in every mailbox of acct
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
  const { data: mailboxes = [], isLoading } = usePromise(getMailboxes);

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search mailboxes...">
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
