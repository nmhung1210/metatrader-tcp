# pylint: disable=W0702,W0718,W0612,C0116,W0719
import argparse
import shutil
import os
import sys
from subprocess import Popen
import asyncio
from asyncio import StreamWriter
from asyncio import StreamReader
import hashlib
import shlex

BUNDLE_DIR = getattr(
    sys, "_MEIPASS", os.path.abspath(os.path.dirname(__file__)))


def start_mt4_terminal(username, password, server, gwport, uid):
    print(
        f"Starting MT4 terminal for {username} on {server} with gwport {gwport}")
    safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
    hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
    terminal_dir = os.path.join(
        ".sessions", "mt4", str(username), safe_server, hash_pw
    )
    terminal = os.path.join(terminal_dir, "terminal.exe")
    config = os.path.join(terminal_dir, "session.conf")
    param = os.path.join(terminal_dir, "MQL4", "Presets", "param.set")
    try:
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt4")), terminal_dir
        )

    except:
        pass
    with open(param, "w", encoding="utf-8") as fparam:
        fparam.write(
            "\n".join(["PORT=" + str(gwport), "UUID=" + str(uid)])
        )

    with open(config, "w", encoding="utf-8") as fconfig:
        fconfig.write(
            "\n".join(
                [
                    "Login=" + str(username),
                    "Password=" + str(password),
                    "Server=" + str(server),
                    "EnableNews=false",
                    "ExpertsEnable=true",
                    "ExpertsTrades=true",
                    "ExpertsDllImport=true",
                    "Script=fxcloud",
                    "ScriptParameters=param.set",
                    "Symbol=FXCLOUD",
                ]
            )
        )

    return Popen([terminal, "session.conf", "/portable"], cwd=terminal_dir)


def start_mt5_terminal(username, password, server, gwport, uid):
    print(
        f"Starting MT5 terminal for {username} on {server} with gwport {gwport}")
    safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
    hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
    terminal_dir = os.path.join(
        ".sessions", "mt5", str(username), safe_server, hash_pw
    )
    terminal = os.path.join(terminal_dir, "terminal64.exe")
    config = os.path.join(terminal_dir, "session.conf")
    param = os.path.join(terminal_dir, "config", "services.ini")
    try:
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt5")), terminal_dir
        )
    except:
        pass
    with open(param, "w", encoding="utf8") as fparam:
        fparam.write(
            "\n".join(
                [
                    "<service>",
                    "name=fxcloud",
                    "path=Services\\fxcloud.ex5",
                    "expertmode=5",
                    "enabled=1",
                    "<inputs>",
                    "PORT=" + str(gwport),
                    "UUID=" + str(uid),
                    "</inputs>",
                    "</service>",
                ]
            )
        )
    with open(config, "w", encoding="utf-8") as fconfig:
        fconfig.write(
            "\n".join(
                [
                    "[Common]",
                    "Login=" + str(username),
                    "Password=" + str(password),
                    "Server=" + server,
                    "NewsEnable=0",
                    "[Experts]",
                    "AllowLiveTrading=1",
                    "Enabled=1",
                    "AllowDllImport=1",
                ]
            )
        )
    return Popen(
        terminal + " /config:session.conf" + " /portable=true", cwd=terminal_dir
    )


def start_terminal(platform, username, password, server, gwport, uid):
    if platform == 'mt4':
        return start_mt4_terminal(username, password, server, gwport, uid)
    elif platform == 'mt5':
        return start_mt5_terminal(username, password, server, gwport, uid)
    else:
        raise ValueError("Unsupported platform. Use 'mt4' or 'mt5'.")


async def handle_client(reader, writer):
    proc = None
    gwserver = None
    state = {
        "isconnected": False,
    }
    try:
        writer.write(b"Welcome to the terminal gateway!\r\n")
        data = await reader.readline()
        print(f"Received data: {data.decode().strip()}")
        if not data:
            writer.close()
            await writer.wait_closed()
            return
        # Parse the received data as command line arguments
        params = shlex.split(data.decode().strip())
        if len(params) != 5:
            writer.write(b"ERR Invalid parameters\n")
            await writer.drain()
            writer.close()
            await writer.wait_closed()
            return
        connect, platform, username, password, server = params
        if connect != "CONNECT":
            writer.write(b"ERR Invalid command\n")
            await writer.drain()
            writer.close()
            await writer.wait_closed()
            return

        uid = os.urandom(16).hex()  # Generate a random UID
        
        async def handle_bridge_client(creader: StreamReader, cwriter: StreamWriter):
            try:
                cuid = (await creader.readline()).decode("utf8").strip()
                print(f"Client UID: {cuid}")
                if cuid != uid:
                    print("Invalid terminal uid. Force closing...")
                    return
                state["isconnected"] = True
                writer.write(b"{\"success\": 1}\r\n")
                
                async def pipe(src, dst):
                    try:
                        while not src.at_eof():
                            data = await src.read(4096)
                            if not data:
                                break
                            dst.write(data)
                    except Exception:
                        pass

                task1 = asyncio.create_task(pipe(reader, cwriter))
                task2 = asyncio.create_task(pipe(creader, writer))
                await asyncio.wait([task1, task2], return_when=asyncio.FIRST_COMPLETED)
                cwriter.close()
                writer.close()
            except:
                pass
            finally:
                gwserver.close()

        gwserver = await asyncio.start_server(
            handle_bridge_client, "127.0.0.1", 0
        )
        gwport = gwserver.sockets[0].getsockname()[1]  # Get the gateway port
        proc = start_terminal(platform, username, password, server, gwport, uid)

        timeout = 30  # seconds
        while not state["isconnected"] and timeout > 0:
            timeout -= 1
            await asyncio.sleep(1)

        if state["isconnected"]:
            await gwserver.wait_closed()

    except Exception as e:
        writer.write(f"ERR {e}\n".encode())
        await writer.drain()
    finally:
        print("Closing connection")
        writer.close()
        await writer.wait_closed()
        if proc is not None:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except Exception:
                proc.kill()

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8888)
    args = parser.parse_args()

    server = await asyncio.start_server(handle_client, args.host, args.port)
    print(f"Server running on {args.host}:{args.port}")
    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
