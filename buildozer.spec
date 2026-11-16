[app]
title = Protocolo de Fuga
package.name = protocolodefuga
package.domain = com.ettoremari
source.dir = .
source.include_exts = py,json,ogg,md
version = 1.0.0
requirements = python3==3.10.11,pygame==2.1.0
orientation = portrait,landscape
fullscreen = 0

android.api = 35
android.minapi = 23
android.ndk = 28c
android.archs = arm64-v8a,armeabi-v7a
p4a.bootstrap = sdl2
p4a.branch = v2026.05.09

[buildozer]
log_level = 2
warn_on_root = 1

