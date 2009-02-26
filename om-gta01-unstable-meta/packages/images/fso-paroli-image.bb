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
  paroli-autostart \
"

paroli_rootfs_postprocess() {
	echo "" >> /etc/freesmartphone/oevents/rules.yaml
	echo "	#" >> /etc/freesmartphone/oevents/rules.yaml
	echo "     # Power-off Handling" >> /etc/freesmartphone/oevents/rules.yaml
	echo "     #" >> /etc/freesmartphone/oevents/rules.yaml
	echo "     trigger: InputEvent()" >> /etc/freesmartphone/oevents/rules.yaml
	echo "     filters:" >> /etc/freesmartphone/oevents/rules.yaml
	echo "              - HasAttr(switch, "POWER")" >> /etc/freesmartphone/oevents/rules.yaml
	echo "              - HasAttr(event, "held")" >> /etc/freesmartphone/oevents/rules.yaml
	echo "              - HasAttr(duration, 5)" >> /etc/freesmartphone/oevents/rules.yaml
	echo "     actions: Command('poweroff')" >> /etc/freesmartphone/oevents/rules.yaml
}

ROOTFS_POSTPROCESS_COMMAND += "paroli_rootfs_postprocess"
