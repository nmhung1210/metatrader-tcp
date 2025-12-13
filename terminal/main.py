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
import logging
import traceback
from datetime import datetime, timedelta
import glob

BUNDLE_DIR = getattr(
    sys, "_MEIPASS", os.path.abspath(os.path.dirname(__file__)))   

log_dir = os.path.join('.sessions', 'logs')

# Ensure log directory exists with proper error handling
try:
    os.makedirs(log_dir, exist_ok=True)
    print(f"Log directory: {log_dir}")
except Exception as e:
    print(f"Error creating log directory: {e}")
    # Fallback to current directory
    log_dir = os.path.join(BUNDLE_DIR, 'logs')
    os.makedirs(log_dir, exist_ok=True)
    print(f"Using fallback log directory: {log_dir}")

# Current log file
current_log_file = os.path.join(log_dir, 'metatrader.log')

# Rotate log file if it exists
if os.path.exists(current_log_file):
    # Get the last modification time of the log file
    try:
        mtime = os.path.getmtime(current_log_file)
        file_date = datetime.fromtimestamp(mtime)
        # Only rotate if the file is from a different day
        if file_date.date() < datetime.now().date():
            archived_log = os.path.join(
                log_dir, 
                f'metatrader-{file_date.strftime("%d%m%Y")}.log'
            )
            shutil.move(current_log_file, archived_log)
            print(f"Rotated log file to: {archived_log}")
    except Exception as e:
        print(f"Error rotating log file: {e}")

log_file = current_log_file
print(f"Log file: {log_file}")

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - [%(filename)s:%(lineno)d] - %(message)s',
    handlers=[
        logging.FileHandler(log_file, encoding='utf-8'),
        logging.StreamHandler(sys.stdout)
    ]
)

logger = logging.getLogger(__name__)

def cleanup_old_logs(log_directory, days_to_keep=3):
    """Remove log files older than specified days"""
    try:
        cutoff_date = datetime.now() - timedelta(days=days_to_keep)
        # Match archived log files pattern: metatrader-DDMMYYYY.log
        log_pattern = os.path.join(log_directory, 'metatrader-*.log')
        log_files = glob.glob(log_pattern)
        
        removed_count = 0
        for log_path in log_files:
            try:
                # Extract date from filename (metatrader-DDMMYYYY.log)
                filename = os.path.basename(log_path)
                date_str = filename.replace('metatrader-', '').replace('.log', '')
                file_date = datetime.strptime(date_str, '%d%m%Y')
                
                if file_date < cutoff_date:
                    os.remove(log_path)
                    removed_count += 1
                    logger.info(f"Removed old log file: {filename}")
            except (ValueError, OSError) as e:
                # Skip files that don't match expected format or can't be removed
                continue
        
        if removed_count > 0:
            logger.info(f"Cleaned up {removed_count} old log file(s)")
        else:
            logger.debug("No old log files to clean up")
    except Exception as e:
        logger.error(f"Error during log cleanup: {e}", exc_info=True)

# Cleanup old logs after logger is initialized
cleanup_old_logs(log_dir, days_to_keep=3)

next_start_time = time.time() + 150
def init_mt4_terminal():
    terminal_dir = os.path.join(
        ".sessions", "default", "mt4"
    )
    terminal = os.path.join(terminal_dir, "terminal.exe")
    try:
        logger.info(f"Initializing MT4 terminal in {terminal_dir}")
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt4")), terminal_dir,
            dirs_exist_ok=True
        )
        logger.info("MT4 terminal directory created successfully")
    except Exception as e:
        logger.error(f"Error creating MT4 terminal directory: {e}", exc_info=True)
    
    try:
        proc = Popen([terminal, "/portable"], cwd=terminal_dir)
        logger.info(f"MT4 terminal process started with PID: {proc.pid}")
        return proc
    except Exception as e:
        logger.error(f"Error starting MT4 terminal process: {e}", exc_info=True)
        raise

def init_mt5_terminal():
    terminal_dir = os.path.join(
        ".sessions", "default", "mt5"
    )
    terminal = os.path.join(terminal_dir, "terminal64.exe")
    try:
        logger.info(f"Initializing MT5 terminal in {terminal_dir}")
        shutil.copytree(
            os.path.abspath(os.path.join(BUNDLE_DIR, "mt5")), terminal_dir,
            dirs_exist_ok=True
        )
        logger.info("MT5 terminal directory created successfully")
    except Exception as e:
        logger.error(f"Error creating MT5 terminal directory: {e}", exc_info=True)
    
    try:
        proc = Popen([terminal, "/portable=true"], cwd=terminal_dir)
        logger.info(f"MT5 terminal process started with PID: {proc.pid}")
        return proc
    except Exception as e:
        logger.error(f"Error starting MT5 terminal process: {e}", exc_info=True)
        raise

def init_terminal():
    async def start():
        try:
            logger.info("Starting default MT4 and MT5 terminals")
            mt4_proc = init_mt4_terminal()
            mt5_proc = init_mt5_terminal()
            await asyncio.sleep(120)
            logger.info("Terminating default terminals after initialization period")
            mt4_proc.terminate()
            mt5_proc.terminate()
        except Exception as e:
            logger.error(f"Error in default terminal initialization: {e}", exc_info=True)

    async def wait_close():
        try:
            await start()
        except Exception as e:
            logger.error(f"Error in wait_close loop: {e}", exc_info=True)

    async def periodic_log_cleanup():
        """Clean up old logs every hour"""
        while True:
            try:
                await asyncio.sleep(3600)  # 1 hour
                logger.info("Running scheduled log cleanup")
                cleanup_old_logs(log_dir, days_to_keep=3)
            except Exception as e:
                logger.error(f"Error in periodic log cleanup: {e}", exc_info=True)

    asyncio.create_task(wait_close())
    asyncio.create_task(periodic_log_cleanup())


def start_mt4_terminal(username, password, server, gwport, uid):
    try:
        logger.info(f"Starting MT4 terminal for {username} on {server} with gwport {gwport}")
        safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
        hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
        default_terminal_dir = os.path.join(
            ".sessions", "default", "mt4"
        )
        terminal_dir = os.path.join(
            ".sessions", "mt4", str(username), safe_server, hash_pw
        )
        terminal = os.path.join(terminal_dir, "terminal.exe")
        config = os.path.join(terminal_dir, "session.conf")
        param = os.path.join(terminal_dir, "MQL4", "Presets", "param.set")
        
        try:
            shutil.copytree(
                default_terminal_dir, terminal_dir,
                dirs_exist_ok=True
            )
            logger.info(f"Created MT4 terminal directory: {terminal_dir}")
        except Exception as e:
            logger.error(f"Error copying MT4 terminal directory: {e}", exc_info=True)
        
        with open(param, "w", encoding="utf-8") as fparam:
            fparam.write(
                "\n".join(["PORT=" + str(gwport), "UUID=" + str(uid)])
            )
        logger.debug(f"Written param file: {param}")

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
        logger.debug(f"Written config file: {config}")

        proc = Popen([terminal, "session.conf", "/portable"], cwd=terminal_dir)
        logger.info(f"MT4 terminal process started with PID: {proc.pid} for user {username}")
        return proc, terminal_dir
    except Exception as e:
        logger.error(f"Error starting MT4 terminal for {username}: {e}", exc_info=True)
        raise
    


def start_mt5_terminal(username, password, server, gwport, uid):
    try:
        logger.info(f"Starting MT5 terminal for {username} on {server} with gwport {gwport}")
        safe_server = "".join(c if c.isalnum() else "_" for c in str(server))
        hash_pw = hashlib.md5(password.encode("utf-8")).hexdigest()
        default_terminal_dir = os.path.join(
            ".sessions", "default", "mt5"
        )
        terminal_dir = os.path.join(
            ".sessions", "mt5", str(username), safe_server, hash_pw
        )
        terminal = os.path.join(terminal_dir, "terminal64.exe")
        config = os.path.join(terminal_dir, "session.conf")
        param = os.path.join(terminal_dir, "config", "services.ini")
        
        try:
            shutil.copytree(
                default_terminal_dir, terminal_dir,
                dirs_exist_ok=True
            )
            logger.info(f"Created MT5 terminal directory: {terminal_dir}")
        except Exception as e:
            logger.error(f"Error copying MT5 terminal directory: {e}", exc_info=True)
        
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
        logger.debug(f"Written param file: {param}")
        
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
        logger.debug(f"Written config file: {config}")
        
        proc = Popen(terminal + " /config:session.conf" + " /portable=true", cwd=terminal_dir)
        logger.info(f"MT5 terminal process started with PID: {proc.pid} for user {username}")
        return proc, terminal_dir
    except Exception as e:
        logger.error(f"Error starting MT5 terminal for {username}: {e}", exc_info=True)
        raise


async def get_terminal(platform, username, password, server, client_writer, client_reader, connect_id):
    uid = str(uuid.uuid4())
    proc = None
    terminal_dir = None
    gwserver = None
    is_client_connected = False

    global next_start_time

    logger.info(f"Terminal request for platform={platform}, username={username}, server={server}")

    while True:
        current_time = time.time()
        if current_time >= next_start_time:
            break
        await asyncio.sleep(1)
        
    next_start_time = time.time() + 180

    async def handle_conn(creader: StreamReader, cwriter: StreamWriter):     
        nonlocal proc, terminal_dir, gwserver, is_client_connected, client_writer  
        global next_start_time
        try:
            cuid = (await creader.readline()).decode("utf8").strip()
            logger.info(f"Client UID received: {cuid}")
            if cuid != uid:
                logger.warning(f"Invalid terminal uid. Expected: {uid}, Received: {cuid}")
                return

            # write connect result to client
            client_writer.write(connect_id.encode() + b" {\"success\": 1}\r\n")
            is_client_connected = True
            next_start_time = time.time() + 1
            logger.info(f"Client successfully connected for {username}")

            async def pipe(src, dst):
                try:
                    while not src.at_eof():
                        data = await src.read(4096)
                        if not data:
                            break
                        dst.write(data)
                except Exception as e:
                    logger.error(f"Error in pipe operation: {e}", exc_info=True)

            task1 = asyncio.create_task(pipe(client_reader, cwriter))
            task2 = asyncio.create_task(pipe(creader, client_writer))
            
            await asyncio.wait([task1, task2], return_when=asyncio.FIRST_COMPLETED)
            cwriter.close()
            client_writer.close()
            logger.info(f"Connection closed for {username}")
                
        except Exception as e:
            logger.error(f"Error handling connection for {username}: {e}", exc_info=True)
        finally:
            next_start_time = time.time() + 120
            if proc is not None:
                logger.info(f"Terminating terminal process {proc.pid} for {username}")
                proc.terminate()
            if gwserver is not None:
                gwserver.close()
            if client_writer is not None:
                client_writer.close()

    try:
        gwserver = await asyncio.start_server(
            handle_conn, "127.0.0.1", 0
        )
        gwport = gwserver.sockets[0].getsockname()[1]  # Get the gateway port
        logger.info(f"Gateway server started on port {gwport} for {username}")
    except Exception as e:
        logger.error(f"Error starting gateway server: {e}", exc_info=True)
        raise
    
    try:
        if platform == 'mt4':
            proc, terminal_dir = start_mt4_terminal(username, password, server, gwport, uid)
        elif platform == 'mt5':
            proc, terminal_dir = start_mt5_terminal(username, password, server, gwport, uid)
        else:
            logger.error(f"Unsupported platform: {platform}")
            raise ValueError("Unsupported platform. Use 'mt4' or 'mt5'.")
    except Exception as e:
        logger.error(f"Error starting {platform} terminal for {username}: {e}", exc_info=True)
        raise

    async def monitor_process():
        nonlocal is_client_connected, client_writer, proc, terminal_dir
        try:
            await asyncio.sleep(180)
            logger.info(f"Checking client connection status for {username}: {is_client_connected}")
            if not is_client_connected:
                client_writer.write(connect_id.encode() + b" {\"success\": 0}\r\n")
                client_writer.close()
                logger.warning(f"No client connected within timeout for {username}. Terminating terminal process...")
                proc.terminate()
            
            while proc.poll() is None:
                await asyncio.sleep(1)
            logger.info(f"Terminal process has exited for {username}. Cleaning up...")
            # while True:
            #     await asyncio.sleep(10)
            #     if terminal_dir and os.path.exists(terminal_dir):
            #         try:
            #             shutil.rmtree(terminal_dir)
            #             logger.info(f"Removed terminal directory: {terminal_dir}")
            #             break
            #         except Exception as e:
            #             logger.error(f"Error removing terminal directory: {e}", exc_info=True)
        except Exception as e:
            logger.error(f"Error in monitor_process for {username}: {e}", exc_info=True)
            
    asyncio.create_task(monitor_process())
    return proc, terminal_dir

def create_handle_client(auth: str = None):
    async def handle_client(reader, writer):
        client_addr = writer.get_extra_info('peername')
        logger.info(f"New client connection from {client_addr}")
        try:
            writer.write(b"Welcome to the terminal gateway!\r\n")           
            auth_request = await reader.readline()
            if not auth_request:
                logger.warning(f"Client {client_addr} disconnected without authentication")
                writer.close()
                await writer.wait_closed()
                return

            params = shlex.split(auth_request.decode().strip()) 
            if len(params) < 3:
                logger.warning(f"Invalid authentication request from {client_addr}: {params}")
                writer.write(b" { \"error\": \"Invalid authentication request\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            req_id, auth_cmd, token  = params
            if auth_cmd == "AUTH":
                if token == auth:
                    writer.write(req_id.encode() + b" {\"success\": 1}\r\n")
                    logger.info(f"Client {client_addr} authenticated successfully")
                else:
                    logger.warning(f"Authentication failed for client {client_addr}")
                    writer.write(req_id.encode() + b" {\"error\": \"Authentication failed\", \"success\": 0}\r\n")
                    await writer.drain()
                    writer.close()
                    return
            else:
                logger.warning(f"Invalid auth command from {client_addr}: {auth_cmd}")
                writer.write(req_id.encode() + b" {\"error\": \"Not authenticated\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            
            connect_request = await reader.readline()
            if not connect_request:
                logger.warning(f"Client {client_addr} disconnected before connect request")
                writer.close()
                await writer.wait_closed()
                return
            
            params = shlex.split(connect_request.decode().strip())
            if len(params) < 6:
                logger.warning(f"Invalid connect request from {client_addr}: {params}")
                writer.write(b" { \"error\": \"Invalid connect request\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

            connect_id,  connect_cmd, platform, username, password, server = params
            if connect_cmd == "CONNECT":
                logger.info(f"Connect request from {client_addr}: platform={platform}, username={username}, server={server}")
                await get_terminal(platform, username, password, server, writer, reader, connect_id)
            else:
                logger.warning(f"Invalid connect command from {client_addr}: {connect_cmd}")
                writer.write(connect_id.encode() + b" {\"error\": \"Invalid command\", \"success\": 0}\r\n")
                await writer.drain()
                writer.close()
                return

        except Exception as e:
            logger.error(f"Error handling client {client_addr}: {e}", exc_info=True)
            writer.close()

    return handle_client

async def main():
    try:
        parser = argparse.ArgumentParser()
        parser.add_argument("--host", default="0.0.0.0")
        parser.add_argument("--port", type=int, default=8888)
        parser.add_argument("--auth-token", default="Fx@2025!#")
        args = parser.parse_args()

        logger.info("=" * 60)
        logger.info("MetaTrader TCP Gateway Server Starting")
        logger.info(f"Host: {args.host}")
        logger.info(f"Port: {args.port}")
        logger.info(f"Log file: {log_file}")
        logger.info("=" * 60)

        init_terminal()

        server = await asyncio.start_server(create_handle_client(args.auth_token), args.host, args.port)
        logger.info(f"Server running on {args.host}:{args.port}")
        async with server:
            await server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Server shutdown requested by user")
    except Exception as e:
        logger.critical(f"Fatal error in main: {e}", exc_info=True)
        raise

if __name__ == "__main__":
    try:
        if sys.platform == "win32":
            asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Application terminated by user")
    except Exception as e:
        logger.critical(f"Fatal error: {e}", exc_info=True)
        sys.exit(1)
