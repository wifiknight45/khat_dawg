#!/usr/bin/env python3

import argparse
import requests
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import subprocess
import sys
import os
import logging
from threading import Thread

# Configure logging
logging.basicConfig(filename='api_client.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# API endpoint (adjust to your server’s IP)
API_URL = "http://localhost:5000"

class APIClient:
    def __init__(self):
        self.developer_mode = False

    def api_request(self, method, endpoint, data=None, headers=None):
        try:
            if method == "GET":
                response = requests.get(f"{API_URL}/{endpoint}", headers=headers)
            elif method == "POST":
                response = requests.post(f"{API_URL}/{endpoint}", json=data, headers=headers)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"API request failed: {e}")
            return {"error": str(e)}

    def run_command(self, command):
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            logger.info(f"Command '{command}' executed: {result.stdout}")
            return result.stdout or result.stderr
        except Exception as e:
            logger.error(f"Command execution failed: {e}")
            return str(e)

def cli_mode(args):
    client = APIClient()
    headers = {"User-Agent": f"{args.platform} {args.version}"}
    
    if args.action == "get_status":
        result = client.api_request("GET", "status", headers=headers)
        print(result)
    elif args.action == "update_status":
        result = client.api_request("POST", "status", {"status": args.status}, headers=headers)
        print(result)
    elif args.action == "health":
        result = client.api_request("GET", "health")
        print(result)

def gui_mode(developer_mode=False):
    client = APIClient()
    client.developer_mode = developer_mode

    root = tk.Tk()
    root.title("API Client - Debian Style")
    root.geometry("600x500")
    root.configure(bg="#2e2e2e")

    style = ttk.Style()
    style.configure("TButton", font=("DejaVu Sans", 10), padding=5, background="#4a4a4a", foreground="white")
    style.configure("TLabel", font=("DejaVu Sans", 10), background="#2e2e2e", foreground="white")
    style.configure("TFrame", background="#2e2e2e")

    # Main frame
    main_frame = ttk.Frame(root)
    main_frame.pack(padx=10, pady=10, fill="both", expand=True)

    # Platform selection
    ttk.Label(main_frame, text="Platform:").grid(row=0, column=0, padx=5, pady=5)
    platform_var = tk.StringVar(value="Android")
    platform_menu = ttk.OptionMenu(main_frame, platform_var, "Android", "Android", "iOS")
    platform_menu.grid(row=0, column=1, padx=5, pady=5)

    ttk.Label(main_frame, text="Version:").grid(row=0, column=2, padx=5, pady=5)
    version_var = tk.StringVar(value="15" if platform_var.get() == "Android" else "18.3")
    version_entry = ttk.Entry(main_frame, textvariable=version_var)
    version_entry.grid(row=0, column=3, padx=5, pady=5)

    # Output display
    output_text = scrolledtext.ScrolledText(main_frame, height=15, width=60, bg="#1e1e1e", fg="white", font=("DejaVu Sans Mono", 10))
    output_text.grid(row=1, column=0, columnspan=4, padx=5, pady=5)

    # Buttons
    def get_status():
        headers = {"User-Agent": f"{platform_var.get()} {version_var.get()}"}
        result = client.api_request("GET", "status", headers=headers)
        output_text.delete(1.0, tk.END)
        output_text.insert(tk.END, str(result))

    def update_status():
        headers = {"User-Agent": f"{platform_var.get()} {version_var.get()}"}
        status = status_entry.get()
        result = client.api_request("POST", "status", {"status": status}, headers=headers)
        output_text.delete(1.0, tk.END)
        output_text.insert(tk.END, str(result))

    ttk.Button(main_frame, text="Get Status", command=get_status).grid(row=2, column=0, pady=5)
    ttk.Label(main_frame, text="New Status:").grid(row=2, column=1, padx=5, pady=5)
    status_entry = ttk.Entry(main_frame)
    status_entry.grid(row=2, column=2, padx=5, pady=5)
    ttk.Button(main_frame, text="Update Status", command=update_status).grid(row=2, column=3, pady=5)

    # Developer Mode
    if developer_mode:
        dev_frame = ttk.LabelFrame(main_frame, text="Developer Mode")
        dev_frame.grid(row=3, column=0, columnspan=4, pady=10, sticky="ew")

        ttk.Label(dev_frame, text="Command:").grid(row=0, column=0, padx=5, pady=5)
        command_entry = ttk.Entry(dev_frame, width=50)
        command_entry.grid(row=0, column=1, padx=5, pady=5)

        def run_command():
            cmd = command_entry.get()
            if cmd.startswith("python"):
                result = client.run_command(f"python3 -c '{cmd[6:]}'")
            else:
                result = client.run_command(cmd)
            output_text.delete(1.0, tk.END)
            output_text.insert(tk.END, result)

        ttk.Button(dev_frame, text="Run Bash/Python", command=run_command).grid(row=0, column=2, pady=5)

    root.mainloop()

def main():
    parser = argparse.ArgumentParser(description="Debian-style API Client for Android 15 and iOS 18.3")
    parser.add_argument('--cli', action='store_true', help="Run in command-line mode")
    parser.add_argument('--gui', action='store_true', help="Run in GUI mode")
    parser.add_argument('--developer', action='store_true', help="Enable developer mode (GUI only)")
    parser.add_argument('--action', choices=['get_status', 'update_status', 'health'], help="CLI action")
    parser.add_argument('--platform', choices=['Android', 'iOS'], default='Android', help="Platform (CLI only)")
    parser.add_argument('--version', default='15', help="Version (CLI only, e.g., 15 or 18.3)")
    parser.add_argument('--status', help="Status to update (CLI only)")

    args = parser.parse_args()

    if args.cli:
        if not args.action:
            parser.error("--action is required in CLI mode")
        cli_mode(args)
    elif args.gui:
        gui_mode(args.developer)
    else:
        print("Please specify --cli or --gui")
        parser.print_help()

if __name__ == "__main__":
    main()
