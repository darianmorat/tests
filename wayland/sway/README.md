## GTK Theming

Sway requires two theming methods to keep all apps looking identical:

- **Native Wayland apps** (Nemo, file pickers) read `gsettings`.
- **XWayland apps** read `gtk-3.0/settings.ini` and `xsettingsd`.

Saved permanently. Run these once in the terminal on a fresh install:

```
gsettings set org.gnome.desktop.interface text-scaling-factor 1.33
gsettings set org.gnome.desktop.interface font-name 'Inter Display 10'
gsettings set org.gnome.desktop.interface cursor-theme 'Adwaita'
```
