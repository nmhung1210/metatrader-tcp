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
from typing import Dict, Tuple, Any
import time

BUNDLE_DIR = getattr(
    sys, "_MEIPASS", os.path.abspath(os.path.dirname(__file__)))

    
request_queues: Dict[str, collections.deque] = {}
active_connections: Dict[str, Tuple[Any, Any, Any, Any, Any]] = {}  # key -> (proc, terminal_dir, is_ready, uid, sockets)

def get_connection_uid(platform: str, username: str, server: str, password: str) -> str:
    """Generate a unique key for connection based on platform, username, and server"""
    return hashlib.sha256(f"{platform}:{username}:{server}:{password}".encode("utf-8")).hexdigest()

def cleanup_connection(platform: str, username: str, server: str, password: str):
    """Remove connection from active connections"""
    uid = get_connection_uid(platform, username, server, password)
    if uid in active_connections:
        del active_connections[uid]
    if uid in request_queues:
        del request_queues[uid]

async def enqueue_request(uid: str, request_data: Any):
    """Add request to queue for the given uid"""
    if uid not in request_queues:
        request_queues[uid] = collections.deque()
    request_queues[uid].append(request_data)

async def dequeue_request(uid: str) -> Any:
    """Get next request from queue for the given uid"""
    if uid in request_queues and request_queues[uid]:
        return request_queues[uid].popleft()
    return None


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

    return Popen([terminal, "session.conf", "/portable"], cwd=terminal_dir), terminal_dir
    


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
    return Popen(terminal + " /config:session.conf" + " /portable=true", cwd=terminal_dir), terminal_dir


async def get_terminal(platform, username, password, server):
    uid = get_connection_uid(platform, username, server, password)
    if uid in active_connections and active_connections[uid] is not None:
        return active_connections[uid]

    proc = None
    terminal_dir = None
    gwserver = None
    sockets = []

    async def handle_conn(creader: StreamReader, cwriter: StreamWriter):
        try:
            cuid = (await creader.readline()).decode("utf8").strip()
            print(f"Client UID: {cuid}")
            if cuid != uid:
                print("Invalid terminal uid. Force closing...")
                return
            active_connections[uid] = (active_connections[uid][0], active_connections[uid][1], True, uid, sockets)
            last_request_at = time.time()
            while True:
                try:
                    if (time.time() - last_request_at) > 60:
                        print("No requests for 60 seconds. Closing terminal connection...")
                        break
                    if (cwriter.is_closing()):
                        break
                    req = await dequeue_request(uid)
                    if req is None:
                        await asyncio.sleep(0.1)
                        continue
                    request, req_writer = req
                    params = shlex.split(request.decode().strip())
                    if (len(params) < 1):
                        continue
                    if (params[0] == "CONNECT"):
                        if params[1] != platform or params[2] != str(username) or params[3] != str(password) or params[4] != str(server):
                            print("Mismatched connection parameters. Ignoring CONNECT request.")
                            req_writer.write(b"{\"success\": 0, \"error\": \"Already connected\"}\r\n")
                        else:
                            req_writer.write(b"{\"success\": 1}\r\n")
                        continue

                    print(f"Forwarding request to terminal: {request.decode().strip()}")
                    cwriter.write(request + b"\r\n")
                    response = await creader.readline()
                    req_writer.write(response)
                    last_request_at = time.time()
                except Exception as e:
                    print(f"Error forwarding request to terminal: {request.decode().strip()}")
                    print(f"Exception details: {e}")

        except Exception as e:
            print(f"Error handling connection: {e}")
        finally:
            if proc is not None:
                print("Terminating terminal process...")
                proc.terminate()

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
        cleanup_connection(platform, username, server, password)
        gwserver.close()
        for socket in sockets:
            socket.close()
            
    asyncio.create_task(monitor_process())
    active_connections[uid] = (proc, terminal_dir, False, uid, sockets)

    return active_connections[uid]

def create_handle_client(auth: str = None):
    async def handle_client(reader, writer):
        proc = None
        gwserver = None
        cuid = None
        is_authenticated = False
        try:
            writer.write(b"Welcome to the terminal gateway!\r\n")
            while True:
                request = await reader.readline()
                print(f"Received data: {request.decode().strip()}")
                if not request:
                    writer.close()
                    await writer.wait_closed()
                    return
                params = shlex.split(request.decode().strip())
                if (len(params) < 1):
                    await writer.drain()
                    writer.close()
                    return

                command = params[0]
                if auth is not None and not is_authenticated and command != "AUTH":
                    writer.write(b"{\"error\": \"Not authenticated\", \"success\": 0}\r\n")
                    await writer.drain()
                    writer.close()
                    return
                
                if command == "AUTH":
                    _, provided_auth = params
                    if provided_auth == auth:
                        is_authenticated = True
                        writer.write(b"{\"success\": 1}\r\n")
                    else:
                        writer.write(b"{\"error\": \"Authentication failed\", \"success\": 0}\r\n")
                        await writer.drain()
                        writer.close()
                        return
                    await writer.drain()
                    continue


                if cuid is not None and active_connections.get(cuid) is None:
                    cuid = None
                    writer.close()
                    return

                if cuid is None and params[0] != "CONNECT":
                    writer.write(b"{\"error\": \"Not connected\", \"success\": 0}\n")
                    await writer.drain()
                    writer.close()
                    return

                if cuid is None and params[0] == "CONNECT":
                    _, platform, username, password, server = params
                    proc, terminal_dir, is_ready, cuid, sockets = await get_terminal(platform, username, password, server)
                    sockets.append(writer)
                    print(f"Using terminal UID: {cuid}")

                await enqueue_request(cuid, (request, writer))

        except Exception as e:
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
