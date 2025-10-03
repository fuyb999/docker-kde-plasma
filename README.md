
### coturn
```shell
sudo docker run --name coturn --restart=always -d -p 3478:3478 -p 3478:3478/udp -p 65500-65535:65500-65535 \
    -p 65500-65535:65500-65535/udp ghcr.nju.edu.cn/coturn/coturn -n --listening-ip="0.0.0.0" --listening-ip="::" \
    --external-ip="192.168.75.16" --min-port=65500 --max-port=65535 --lt-cred-mech --user=n0TaRealCoTURNAuthSecret:ThatIsSixtyFourLengthsLongPlaceholdPlace

```

### moonlight undefined symbol: SDL_GetTouchName
```shell
wget https://www.libsdl.org/release/SDL2-2.0.22.tar.gz
./configure --prefix=/usr/     --enable-video-x11     --enable-alsa     --enable-pulseaudio     --enable-input-libinput     --enable-h264     --enable-hevc     --enable-network     --enable-openssl
make -j$(nproc)
sudo make install
sudo mv build/.libs/libSDL2-2.0.so.0.22.0 /usr/lib/x86_64-linux-gnu/libSDL2-2.0.so.0
```

```text
Go
Python
JRebel and XRebel
JRebel mybatisPlus extension
Cool Request(REST Client)
Grep Console
Regexp Tester
any-rule
Regex Rename Files
Json Parser And Code Generation
StringManipulation
Remote File Systems
Kafka
.env
.ignore
JPA Buddy
PowerShell
Native Terminal
NexChat


ansible
JetBrains AI Assistant
CodeGPT


Rainbow Brackets
Elasticsearch
Spring Debugger
BashSupport Pro
Nginx Configuration Pro
MyBatis Log
React Native Console
MyBatisCodeHelperPro
Fast Request
Spring Boot Helper
Extra Icons
Odoo IDE
ANSI Highlighter Premium
Redis
Redis Client
Kafka Client
Gerry Themes Pro
SQLFormatter
Snapshots for AI
AICommit

```

```shell
sudo tar --exclude=config/IdeaProjects \
    --exclude=config/模板 \
    --exclude=config/Downloads \
    --exclude=config/Documents \
    --exclude=*/.lingma/* \
    --exclude=*/lingma* \
    --exclude=*/.tabnine/* \
    --exclude=*/TabNine* \
    --exclude=config/.cache/mesa_shader_cache \
    --exclude=config/config/.local/share/Kingsoft \
    --exclude=config/.local/share/Kingsoft \
    --exclude=config/.cache/google-chrome \
    --exclude=config/.config/google-chrome \
    --exclude=config/.config/ibus/bus \
    --exclude=config/.local/share/DBeaverData \
    --exclude=config/.cache/mozilla \
    --exclude=config/.mozilla/firefox \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/editor \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/plugins/*.zip \
    --exclude=config/.config/JetBrains/IntelliJIdea2025.2/tasks \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/plugins/imageCache \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/log \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/index \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/full-line \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/semantic-search/indices \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/frameworks/detection \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/projects \
    --exclude=config/.cache/JetBrains/IntelliJIdea2025.2/jcef_cache/Cache \
    -Jcvf config.tar.xz config/

split -b 100M config.tar.xz config-idea2025.2.2.tar.xz.part

sudo tar -Jcvf full-line.tar.xz config/.cache/JetBrains/IntelliJIdea2025.2/full-line

split -b 100M full-line.tar.xz full-line-idea2025.2.2.tar.xz.part
```




