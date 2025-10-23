# FacelessWebServer Diagnostic Report
Generated: 2025-10-23T14:07:55-04:00
Host: noface

## 1) Summary
- First-boot completion marker: missing
- First-boot service: is-active=failed
unknown; is-failed=failed
- App service (no_face_core.service): is-active=inactive
unknown; is-failed=inactive
unknown
- USB block device detected: /dev/sda
- /mnt/usb/Videos: missing
- SSH deploy key (/home/noface/.ssh/id_ed25519): missing
- Network to github.com (ICMP ping): yes
- Likely root cause: First-boot service failed; automation likely did not complete
- Confidence: medium

## 2) First-boot service
<details>
<summary>× faceless-first-boot.service - FacelessWebServer First Boot Setup
     Loaded: loaded (/etc/systemd/system/faceless-first-boot.service; enabled; preset: enabled)
     Active: failed (Result: exit-code) since Thu 2025-10-23 13:33:36 EDT; 34min ago
 Invocation: 267c008bc6f5470bb7c32ffa2a9a9be0
    Process: 958 ExecStart=/usr/local/bin/faceless-first-boot.sh (code=exited, status=1/FAILURE)
   Main PID: 958 (code=exited, status=1/FAILURE)
        CPU: 1.516s

Oct 23 13:33:36 noface faceless-first-boot.sh[1074]: [2025-10-23 13:33:36]       └── deploy_key      (SSH private key)
Oct 23 13:33:36 noface faceless-first-boot.sh[1077]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1080]: [2025-10-23 13:33:36] Please:
Oct 23 13:33:36 noface faceless-first-boot.sh[1083]: [2025-10-23 13:33:36]   1. Insert USB drive with Videos/ directory
Oct 23 13:33:36 noface faceless-first-boot.sh[1086]: [2025-10-23 13:33:36]   2. Create .deploy/deploy_key on the USB drive
Oct 23 13:33:36 noface faceless-first-boot.sh[1089]: [2025-10-23 13:33:36]   3. Reboot or run: sudo systemctl start faceless-first-boot.service
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Main process exited, code=exited, status=1/FAILURE
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Failed with result 'exit-code'.
Oct 23 13:33:36 noface systemd[1]: Failed to start faceless-first-boot.service - FacelessWebServer First Boot Setup.
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Consumed 1.516s CPU time.</summary>

<pre>
× faceless-first-boot.service - FacelessWebServer First Boot Setup
     Loaded: loaded (/etc/systemd/system/faceless-first-boot.service; enabled; preset: enabled)
     Active: failed (Result: exit-code) since Thu 2025-10-23 13:33:36 EDT; 34min ago
 Invocation: 267c008bc6f5470bb7c32ffa2a9a9be0
    Process: 958 ExecStart=/usr/local/bin/faceless-first-boot.sh (code=exited, status=1/FAILURE)
   Main PID: 958 (code=exited, status=1/FAILURE)
        CPU: 1.516s

Oct 23 13:33:36 noface faceless-first-boot.sh[1074]: [2025-10-23 13:33:36]       └── deploy_key      (SSH private key)
Oct 23 13:33:36 noface faceless-first-boot.sh[1077]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1080]: [2025-10-23 13:33:36] Please:
Oct 23 13:33:36 noface faceless-first-boot.sh[1083]: [2025-10-23 13:33:36]   1. Insert USB drive with Videos/ directory
Oct 23 13:33:36 noface faceless-first-boot.sh[1086]: [2025-10-23 13:33:36]   2. Create .deploy/deploy_key on the USB drive
Oct 23 13:33:36 noface faceless-first-boot.sh[1089]: [2025-10-23 13:33:36]   3. Reboot or run: sudo systemctl start faceless-first-boot.service
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Main process exited, code=exited, status=1/FAILURE
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Failed with result 'exit-code'.
Oct 23 13:33:36 noface systemd[1]: Failed to start faceless-first-boot.service - FacelessWebServer First Boot Setup.
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Consumed 1.516s CPU time.
</pre>
</details>

<details>
<summary></summary>

<pre>
Oct 23 13:25:39 noface systemd[1]: Starting faceless-first-boot.service - FacelessWebServer First Boot Setup...
Oct 23 13:25:39 noface faceless-first-boot.sh[960]: [2025-10-23 13:25:39] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Oct 23 13:25:39 noface faceless-first-boot.sh[963]: [2025-10-23 13:25:39] 🚀 FacelessWebServer First Boot Setup Starting
Oct 23 13:25:39 noface faceless-first-boot.sh[966]: [2025-10-23 13:25:39] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Oct 23 13:25:39 noface faceless-first-boot.sh[970]: [2025-10-23 13:25:39] 📀 Waiting for USB drive (will auto-mount if needed)...
Oct 23 13:33:36 noface faceless-first-boot.sh[1056]: [2025-10-23 13:33:36] ❌ ERROR: USB drive not found after 180s
Oct 23 13:33:36 noface faceless-first-boot.sh[1059]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1062]: [2025-10-23 13:33:36] Expected USB structure:
Oct 23 13:33:36 noface faceless-first-boot.sh[1065]: [2025-10-23 13:33:36]   /mnt/usb/
Oct 23 13:33:36 noface faceless-first-boot.sh[1068]: [2025-10-23 13:33:36]   ├── Videos              (video content)
Oct 23 13:33:36 noface faceless-first-boot.sh[1071]: [2025-10-23 13:33:36]   └── .deploy/
Oct 23 13:33:36 noface faceless-first-boot.sh[1074]: [2025-10-23 13:33:36]       └── deploy_key      (SSH private key)
Oct 23 13:33:36 noface faceless-first-boot.sh[1077]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1080]: [2025-10-23 13:33:36] Please:
Oct 23 13:33:36 noface faceless-first-boot.sh[1083]: [2025-10-23 13:33:36]   1. Insert USB drive with Videos/ directory
Oct 23 13:33:36 noface faceless-first-boot.sh[1086]: [2025-10-23 13:33:36]   2. Create .deploy/deploy_key on the USB drive
Oct 23 13:33:36 noface faceless-first-boot.sh[1089]: [2025-10-23 13:33:36]   3. Reboot or run: sudo systemctl start faceless-first-boot.service
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Main process exited, code=exited, status=1/FAILURE
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Failed with result 'exit-code'.
Oct 23 13:33:36 noface systemd[1]: Failed to start faceless-first-boot.service - FacelessWebServer First Boot Setup.
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Consumed 1.516s CPU time.
</pre>
</details>

<details>
<summary>`sudo journalctl -u faceless-first-boot.service --no-pager (last 200 lines)`</summary>

<pre>
Oct 23 13:25:39 noface systemd[1]: Starting faceless-first-boot.service - FacelessWebServer First Boot Setup...
Oct 23 13:25:39 noface faceless-first-boot.sh[960]: [2025-10-23 13:25:39] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Oct 23 13:25:39 noface faceless-first-boot.sh[963]: [2025-10-23 13:25:39] 🚀 FacelessWebServer First Boot Setup Starting
Oct 23 13:25:39 noface faceless-first-boot.sh[966]: [2025-10-23 13:25:39] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Oct 23 13:25:39 noface faceless-first-boot.sh[970]: [2025-10-23 13:25:39] 📀 Waiting for USB drive (will auto-mount if needed)...
Oct 23 13:33:36 noface faceless-first-boot.sh[1056]: [2025-10-23 13:33:36] ❌ ERROR: USB drive not found after 180s
Oct 23 13:33:36 noface faceless-first-boot.sh[1059]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1062]: [2025-10-23 13:33:36] Expected USB structure:
Oct 23 13:33:36 noface faceless-first-boot.sh[1065]: [2025-10-23 13:33:36]   /mnt/usb/
Oct 23 13:33:36 noface faceless-first-boot.sh[1068]: [2025-10-23 13:33:36]   ├── Videos              (video content)
Oct 23 13:33:36 noface faceless-first-boot.sh[1071]: [2025-10-23 13:33:36]   └── .deploy/
Oct 23 13:33:36 noface faceless-first-boot.sh[1074]: [2025-10-23 13:33:36]       └── deploy_key      (SSH private key)
Oct 23 13:33:36 noface faceless-first-boot.sh[1077]: [2025-10-23 13:33:36]
Oct 23 13:33:36 noface faceless-first-boot.sh[1080]: [2025-10-23 13:33:36] Please:
Oct 23 13:33:36 noface faceless-first-boot.sh[1083]: [2025-10-23 13:33:36]   1. Insert USB drive with Videos/ directory
Oct 23 13:33:36 noface faceless-first-boot.sh[1086]: [2025-10-23 13:33:36]   2. Create .deploy/deploy_key on the USB drive
Oct 23 13:33:36 noface faceless-first-boot.sh[1089]: [2025-10-23 13:33:36]   3. Reboot or run: sudo systemctl start faceless-first-boot.service
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Main process exited, code=exited, status=1/FAILURE
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Failed with result 'exit-code'.
Oct 23 13:33:36 noface systemd[1]: Failed to start faceless-first-boot.service - FacelessWebServer First Boot Setup.
Oct 23 13:33:36 noface systemd[1]: faceless-first-boot.service: Consumed 1.516s CPU time.
</pre>
</details>

