# MANIFEST del backup Devuan migration

**Fecha:** 2026-08-09 00:59:37

**Backup dir:** `/home/ezequiel/devuan-migration/backup`

## Resumen por categoria

| Categoria | Origen | Destino | Archivos | Tamano |
|---|---|---|---|---|
| wm | /home/ezequiel/.config/sway | wm/sway | 15 archivos | 12421 B |
| wm | /home/ezequiel/.config/mango | wm/mango | 40 archivos | 120925 B |
| terminal | /home/ezequiel/.config/foot | terminal/foot | 2 archivos | 1037 B |
| shell | /home/ezequiel/.config/fish | shell/fish | 2 archivos | 6435 B |
| noctalia | /home/ezequiel/.config/noctalia | noctalia/config/noctalia | 97 archivos | 456636 B |
| noctalia | /home/ezequiel/.local/state/noctalia | noctalia/state/noctalia | 650 archivos | 22771755 B |
| portal | /home/ezequiel/.config/xdg-desktop-portal | portal/xdg-desktop-portal | 2 archivos | 310 B |
| portal | /etc/xdg-desktop-portal | (saltado) | -- | -- | no existe |
| home-manager | /home/ezequiel/.config/home-manager | home-manager/home-manager | 3 archivos | 9482 B |
| appearance | /home/ezequiel/.local/share/themes | appearance/themes | 124 archivos | 2215298 B |
| appearance | /home/ezequiel/.local/share/icons | appearance/icons | 64 archivos | 438819 B |
| appearance | /home/ezequiel/.local/share/fonts | appearance/fonts | 173 archivos | 753039496 B |
| emptty | /etc/emptty/conf-tty7 | emptty/etc/emptty/conf-tty7 | 1 archivo | 146 B (sudo, literal root:root 640) |
| emptty | /etc/emptty/motd | emptty/etc/emptty/motd | 1 archivo | 537 B (sudo, literal root:root 644) |
| pam | /etc/pam.d/emptty | pam/etc/pam.d/emptty | 1 archivo | 1999 B (sudo, literal root:root 644) |

## Total

| Categoria | Tamano total |
|---|---|
| wm | 133346 B |
| terminal | 1037 B |
| shell | 6435 B |
| noctalia | 23228391 B |
| portal | 310 B |
| home-manager | 9482 B |
| appearance | 755693613 B |
| emptty | 683 B (literal) |
| pam | 1999 B (literal) |

## Notas

- `/etc/xdg-desktop-portal` no existe en el sistema actual; se saltea con nota (no es error).
- Las categorias `emptty` y `pam` se respaldaron con `sudo cp -a` para preservar ownership literal (root:root, modo 640/644).
- Se detectaron repos git embebidos en `noctalia/state/noctalia/plugins/sources/{community,official}/repo`. Los archivos estan copiados completos en el backup (con sus `.git`), pero git los trackea como gitlinks. Para usar el backup, no afecta. Si se clona el backup repo, esos dirs no aparecen via clone (necesitan tar).
- La categoria `appearance` pesa ~756 MB casi todos en `fonts/` (753 MB / 173 archivos TTF).
- No se incluyen sha256sums (decision confirmada). Verificacion post-restore comparando paths y arboles de archivos.
- El backup NO esta comprimido. Para comprimir a `.tar.zst`: `tar --zstd -cf devuan-backup.tar.zst backup/` (lo haces vos manualmente).
