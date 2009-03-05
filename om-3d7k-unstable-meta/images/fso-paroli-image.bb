require fso-zhone-image.bb

ILLUME_THEME = ""

# not many extra apps
GTK_INSTALL = " \
   vala-terminal \
"

GAMES_INSTALL = ""
APPS_INSTALL = ""

# fso+zhone
ZHONE_INSTALL = "\
  task-fso-compliance \
  paroli \
  paroli-theme \
  paroli-autostart \
"
