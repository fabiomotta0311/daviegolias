@echo off
title Abrir Editor do Godot - Davi e Golias
echo Abrindo o Godot Editor...
start "" "%~dp0engine\Godot_v4.7.2-stable_win64.exe" -e --path "%~dp0."
exit
