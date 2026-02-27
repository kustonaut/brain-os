# Inbox — Landing Zone

Drop new files here. The daily pipeline (`parse_inbox.ps1`) will automatically route them to the correct project folder based on keywords in `config.json`.

## Supported Formats
- `.md`, `.txt` — Markdown and text files
- `.docx`, `.pptx`, `.xlsx` — Office documents
- `.pdf` — PDF files (text extraction)
- `.msg` — Outlook message files

## Force Routing
Create a subfolder matching your project ID to force routing:
```
_Inbox/project-alpha/my-doc.docx  → routed to 01_Project_Alpha/
_Inbox/project-beta/notes.md      → routed to 02_Project_Beta/
```

Processed files are moved to `_archived_root_files/`.
