FROM aerokube/selenoid:latest-release

COPY browsers.json /etc/selenoid/browsers.json

ENTRYPOINT ["/usr/bin/selenoid", "-listen", ":4444", "-conf", "/etc/selenoid/browsers.json", "-video-output-dir", "/opt/selenoid/video/"]

CMD ["-conf", "/etc/selenoid/browsers.json"]