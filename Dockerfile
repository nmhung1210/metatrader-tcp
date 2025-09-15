FROM nmhung1210/repo:wine64 AS builder

WORKDIR /app
COPY . .
RUN wine build.bat


FROM nmhung1210/repo:wine64slim
WORKDIR /app

COPY --from=builder /app/dist/main.exe /app/app.exe
ADD entrypoint.sh /bin/entrypoint.sh
RUN chmod a+x /bin/entrypoint.sh

ENTRYPOINT [ "/bin/entrypoint.sh" ]