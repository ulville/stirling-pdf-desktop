#!/usr/bin/bash

if [ $EUID -eq 0 ]; then
    echo "This script is meant to run as a regular user"
    exit 1
fi

echo "-> Checking if podman available"

if command -v podman >/dev/null 2>&1; then
    container_program="podman"
else
    echo "This script requires podman to be installed on the system. Please install if before running this installer."
    exit 1
fi

echo "-> Detected $container_program"

echo "-> Pulling container from docker.io"
$container_program pull docker.io/stirlingtools/stirling-pdf

echo "Generating run script"
cat > "/tmp/run-stirling-pdf.sh" <<EOF
#!/usr/bin/bash

URL=http://localhost:5152
try=0
res="\$(curl -o /dev/null -s -w "%{http_code}\\n" \$URL)"

if [ \$res -ne 200 ]; then
    $container_program run -d \\
        -p 5152:8080 \\
        -v \$HOME/.local/share/trainingData:/usr/share/tessdata:Z \\
        docker.io/stirlingtools/stirling-pdf:latest &&

    while [ \$res -ne 200 ] && [ \$try -le 100 ]
    do
        sleep 0.5 &&
        res="\$(curl -o /dev/null -s -w "%{http_code}\n" \$URL)"
        ((try++))
        echo Try: \$try
        echo Res: \$res
    done
fi
xdg-open \$URL
EOF

echo "-> Adding run script to $HOME/.local/bin/"
echo "-> Make sure this directory is in your PATH"
test -d "$HOME/.local/bin" || mkdir -d "$HOME/.local/bin"
test -d "$HOME/.local/share/trainingData" || mkdir -d "$HOME/.local/share/trainingData"
cp "/tmp/run-stirling-pdf.sh" "$HOME/.local/bin/run-stirling-pdf"
chmod +x "$HOME/.local/bin/run-stirling-pdf"

echo "-> Downloading icon from Stirling-PDF github repo"

install_and_run_curl ()
{
    echo "-> Installing curl"
    sudo $1 $2 curl &&
    curl -o "/tmp/stirling-transparent.svg" https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF/main/docs/stirling-transparent.svg
}

if command -v curl >/dev/null 2>&1; then
    curl -o "/tmp/stirling-transparent.svg" https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF/main/docs/stirling-transparent.svg
elif command -v apt >/dev/null 2>&1; then
    install_and_run_curl apt install
elif command -v dnf >/dev/null 2>&1; then
    install_and_run_curl dnf install
elif command -v pacman >/dev/null 2>&1; then
    install_and_run_curl pacman -S
else
    echo "-> !!! curl is not installed on the system. Please install curl and try again to have an icon !!!" && exit 2
fi

echo "-> Installing icon to user's icon directory"
test -d "$HOME/.local/share/icons/hicolor/48x48/apps" || mkdir -d "$HOME/.local/share/icons/hicolor/48x48/apps"
test -d "$HOME/.local/share/icons/hicolor/scalable/apps" || mkdir -d "$HOME/.local/share/icons/hicolor/scalable/apps"
cp "/tmp/stirling-transparent.svg" "$HOME/.local/share/icons/hicolor/48x48/apps/"
cp "/tmp/stirling-transparent.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/"
xdg-icon-resource forceupdate

echo "-> Creating desktop menu entry"
test -d "$HOME/.local/share/applications" || mkdir -d "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/stirling-pdf.desktop" <<EOF
[Desktop Entry]
Name=Stirling PDF
Comment=Open Stirling PDF Web UI in default browser
Keywords=document;s-pdf;pdf;
Exec=run-stirling-pdf
Categories=Office;
Terminal=false
Icon=stirling-transparent
Type=Application
EOF

xdg-desktop-menu forceupdate
