FROM nmhung1210/repo:wine64 AS builder

WORKDIR /app
COPY . .
RUN wine build.bat


FROM nmhung1210/repo:wine64slim
WORKDIR /app

COPY --from=builder /app/dist/main.exe /app/app.exe

ENTRYPOINT [ "xvfb-run" ]
CMD [ "--auto-servernum", "--server-args=\"-screen 0 8x8x8\"", "wine", "/app/app.exe" ]