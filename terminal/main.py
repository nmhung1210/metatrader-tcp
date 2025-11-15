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
import collections
import time
import uuid

BUNDLE_DIR = getattr(
    sys, "_MEIPASS", os.path.abspath(os.path.dirname(__file__)))   


def start_mt4_terminal(username, password, server, gwport, uid):
    print(
        f"Starting MT4 terminal for {username} on {server} with gwport {gwport}")
    safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
    hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
    terminal_dir = os.path.join(
        ".sessions", "mt4", str(username), safe_server, uid
    )
    terminal = os.path.join(terminal_dir, "terminal.exe")
    config = os.path.join(terminal_dir, "session.conf")
    param = os.path.join(terminal_dir, "MQL4", "Presets", "param.set")
    try:
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt4")), terminal_dir,
            dirs_exist_ok=True
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

    return Popen([terminal, "session.conf", "/portable"], cwd=terminal_dir), terminal_dir
    


def start_mt5_terminal(username, password, server, gwport, uid):
    print(
        f"Starting MT5 terminal for {username} on {server} with gwport {gwport}")
    safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
    hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
    terminal_dir = os.path.join(
        ".sessions", "mt5", str(username), safe_server, uid
    )
    terminal = os.path.join(terminal_dir, "terminal64.exe")
    config = os.path.join(terminal_dir, "session.conf")
    param = os.path.join(terminal_dir, "config", "services.ini")
    try:
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt5")), terminal_dir,
            dirs_exist_ok=True
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
    return Popen(terminal + " /config:session.conf" + " /portable=true", cwd=terminal_dir), terminal_dir


async def get_terminal(platform, username, password, server, client_writer, client_reader, connect_id):
    uid = str(uuid.uuid4())
    proc = None
    terminal_dir = None
    gwserver = None

    async def handle_conn(creader: StreamReader, cwriter: StreamWriter):       
        try:
            cuid = (await creader.readline()).decode("utf8").strip()
            print(f"Client UID: {cuid}")
            if cuid != uid:
                print("Invalid terminal uid. Force closing...")
                return

            # write connect result to client
            client_writer.write(connect_id.encode() + b" {\"success\": 1}\r\n")
            await client_writer.drain()

            last_request_at = time.time()   
            while True:
                if (time.time() - last_request_at) > 600:
                    print("No requests for 600 seconds. Closing terminal connection...")
                    break

                if (cwriter.is_closing()):
                    break

                request = await client_reader.readline()
                if not request:
                    await client_writer.drain() 
                    client_writer.close()
                    break

                params = shlex.split(request.decode().strip())
                if (len(params) < 2):
                    await client_writer.drain()
                    client_writer.close()
                    return

                print(f"Forwarding request to terminal: {request.decode().strip()}")
                cwriter.write(request + b"\r\n")
                await cwriter.drain()

                # read for response
                response = await creader.readline()
                
                client_writer.write(response)
                await client_writer.drain()

                # update last request time
                last_request_at = time.time()
                

        except Exception as e:
            print(f"Error handling connection: {e}")
        finally:
            if proc is not None:
                print("Terminating terminal process...")
                proc.terminate()
            if gwserver is not None:
                gwserver.close()
            if client_writer is not None:
                client_writer.close()

    gwserver = await asyncio.start_server(
        handle_conn, "127.0.0.1", 0
    )
    gwport = gwserver.sockets[0].getsockname()[1]  # Get the gateway port
    
    if platform == 'mt4':
        proc, terminal_dir = start_mt4_terminal(username, password, server, gwport, uid)
    elif platform == 'mt5':
        proc, terminal_dir = start_mt5_terminal(username, password, server, gwport, uid)
    else:
        raise ValueError("Unsupported platform. Use 'mt4' or 'mt5'.")

    async def monitor_process():
        while proc.poll() is None:
            await asyncio.sleep(1)
        print("Terminal process has exited. Cleaning up...")
        while True:
            await asyncio.sleep(10)
            if terminal_dir and os.path.exists(terminal_dir):
                try:
                    shutil.rmtree(terminal_dir)
                    print(f"Removed terminal directory: {terminal_dir}")
                    break
                except Exception as e:
                    print(f"Error removing terminal directory: {e}")
            
    asyncio.create_task(monitor_process())

    return proc, terminal_dir

def create_handle_client(auth: str = None):
    async def handle_client(reader, writer):
        try:
            writer.write(b"Welcome to the terminal gateway!\r\n")           
            auth_request = await reader.readline()
            if not auth_request:
                writer.close()
                await writer.wait_closed()
                return

            params = shlex.split(auth_request.decode().strip()) 
            if len(params) < 3:
                writer.write(b" { \"error\": \"Invalid authentication request\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            req_id, auth_cmd, token  = params
            if auth_cmd == "AUTH":
                if token == auth:
                    writer.write(req_id.encode() + b" {\"success\": 1}\r\n")
                else:
                    writer.write(req_id.encode() + b" {\"error\": \"Authentication failed\", \"success\": 0}\r\n")
                    await writer.drain()
                    writer.close()
                    return
            else:
                writer.write(req_id.encode() + b" {\"error\": \"Not authenticated\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            
            connect_request = await reader.readline()
            if not connect_request:
                writer.close()
                await writer.wait_closed()
                return
            
            params = shlex.split(connect_request.decode().strip())
            if len(params) < 6:
                writer.write(b" { \"error\": \"Invalid connect request\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            connect_id,  connect_cmd, platform, username, password, server = params
            if connect_cmd == "CONNECT":
                await get_terminal(platform, username, password, server, writer, reader, connect_id)
            else:
                writer.write(connect_id.encode() + b" {\"error\": \"Invalid command\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

        except Exception as e:
            writer.close()
            print(f"Error handling client: {e}")

    return handle_client

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=8888)
    parser.add_argument("--auth-token", default="Fx@2025!#")
    args = parser.parse_args()

    server = await asyncio.start_server(create_handle_client(args.auth_token), args.host, args.port)
    print(f"Server running on {args.host}:{args.port}")
    async with server:
        await server.serve_forever()

if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(main())
