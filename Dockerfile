FROM nmhung1210/repo:wine64 AS builder

WORKDIR /app
COPY terminal .
RUN wine build.bat


FROM nmhung1210/repo:wine64slim
WORKDIR /app

COPY --from=builder /app/dist/main.exe /app/app.exe
COPY entrypoint.sh entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 8888

ENTRYPOINT [ "/app/entrypoint.sh" ]

