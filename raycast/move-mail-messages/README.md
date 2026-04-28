# Move Mail Messages

Moves selected messages in Mail to a selected Mailbox.

## Resources
- Why Gmail move doesn't behave the same way as Apple: [Deep Dive into Filing Messages with AppleScript](https://msgfiler.wordpress.com/2024/02/12/a-deep-dive-into-filing-mail-messages-using-applescript/)
  - Gmail messages can remain in Inbox when moved via AppleScript alone, so this command uses a Gmail-specific move-then-archive flow.
  - Archive must happen after the move. Archiving first can cause Mail to advance selection and archive the message below the one originally selected.
