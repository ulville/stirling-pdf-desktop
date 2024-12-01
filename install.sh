#!/usr/bin/bash

if [ $EUID -eq 0 ]; then
    echo "This script is meant to run as a regular user"
    exit 1
fi

echo "-> Checking if docker or podman available"

if command -v docker >/dev/null 2>&1; then
    container_program="docker"
elif command -v podman >/dev/null 2>&1; then
    container_program="podman"
else
    echo "This script requires docker or podman to be installed on the system. Please install one of them before running this installer."
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
cp "/tmp/run-stirling-pdf.sh" "$HOME/.local/bin/run-stirling-pdf"
chmod +x "$HOME/.local/bin/run-stirling-pdf"

echo "-> Downloading icon from Stirling-PDF github repo"
curl -o "/tmp/stirling-transparent.svg" https://raw.githubusercontent.com/Stirling-Tools/Stirling-PDF/main/docs/stirling-transparent.svg

echo "-> Installing icon to user's icon directory"
cp "/tmp/stirling-transparent.svg" "$HOME/.local/share/icons/hicolor/48x48/apps/"
cp "/tmp/stirling-transparent.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/"
xdg-icon-resource forceupdate

echo "-> Creating desktop menu entry"
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
