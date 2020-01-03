#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
---
name: ma.py
description: Main program file
copyright: 2014-2019 Marcio Pessoa
people:
  developers:
  - name: Marcio Pessoa
    email: marcio.pessoa@gmail.com
change-log: Check CHANGELOG.md file.
"""

# Check Python version
import sys
if not (sys.version_info.major == 3 and sys.version_info.minor >= 6):
    print("This progarm requires Python 3.6 or higher!")
    print("You are using Python {}.{}." .
          format(sys.version_info.major, sys.version_info.minor))
    sys.exit(1)

# Check and import modules
try:
    # Ubuntu default modules
    import argparse
    import os.path
    import time
    import subprocess
    # Myself modules
    import tools.echo.echo as echo
    from tools.device.device import DeviceProperties
    from tools.file.file import File
    from tools.session.session import Session
except ImportError as err:
    print("Could not load module. " + str(err))
    sys.exit(True)

__version__ = 0.91


class MakerAssist():  # pylint: disable=too-many-instance-attributes
    """
    description:
    reference:
    - Links
      https://docs.python.org/2/library/argparse.html
      http://chase-seibert.github.io/blog/
    """

    def __init__(self):
        self.program_name = "ma"
        self.program_date = "2020-01-02"
        self.program_description = "ma - Maker Assist"
        self.program_copyright = "Copyright (c) 2014-2020 Marcio Pessoa"
        self.program_license = "GPLv2. There is NO WARRANTY."
        self.program_website = "https://github.com/marcio-pessoa/makerassist"
        self.program_contact = "Marcio Pessoa <marcio.pessoa@gmail.com>"
        self.__config_file = os.path.join(os.getenv('HOME', ''), '.device.json')
        self.__id = None
        self.__firmware = None
        self.__device = None
        self.__config = None
        self.__session = None
        self.__all_devices = None
        self.__only_connected = None
        header = (self.program_name + ' <command> [<args>]\n\n' +
                  'commands:\n' +
                  '  verify         check firmware code sintax\n' +
                  '  upload         upload firmware to device\n' +
                  '  list           list devices\n\n')
        footer = (self.program_copyright + '\n' +
                  'License: ' + self.program_license + '\n' +
                  'Website: ' + self.program_website + '\n' +
                  'Contact: ' + self.program_contact + '\n')
        examples = ('examples:\n' +
                    '  ' + self.program_name + ' list -v4\n' +
                    '  ' + self.program_name + ' verify --id x6 --verbosity=3\n' +
                    '  ' + self.program_name + ' upload\n')
        self.version = (self.program_description + " " +
                        str(__version__) + " (" +
                        self.program_date + ")")
        epilog = (examples + '\n' + footer)
        parser = argparse.ArgumentParser(
            prog=self.program_name,
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog=epilog,
            add_help=True,
            usage=header)
        parser.add_argument('command', help='command to run')
        parser.add_argument('-V', '--version',
                            action='version',
                            version=self.version,
                            help='show version information and exit')
        if len(sys.argv) < 2:
            self.list()
            sys.exit(False)
        args = parser.parse_args(sys.argv[1:2])
        if not hasattr(self, args.command):
            echo.erro('Unrecognized command')
            parser.print_help()
            sys.exit(True)
        getattr(self, args.command)()

    def verify(self):
        """
        description:
        """
        parser = argparse.ArgumentParser(
            prog=self.program_name + ' verify',
            description='check code')
        parser.add_argument(
            '-i', '--id',
            default=None,
            help='device ID')
        parser.add_argument(
            '-d', '--date',
            action="store_true",
            help='display current date and time')
        parser.add_argument(
            '-a', '--all',
            action="store_true",
            help='show even disabled devices')
        parser.add_argument(
            '-v', '--verbosity',
            type=int,
            default=3,
            choices=[0, 1, 2, 3, 4],
            help='verbose mode, options: ' +
            '0 Quiet, 1 Errors (default), 2 Warnings, 3 Info, 4 Debug')
        args = parser.parse_args(sys.argv[2:])
        echo.level(args.verbosity)
        echo.infoln(self.version)
        if args.date:
            echo.infoln('Started at: ' + time.strftime('%Y-%m-%d %H:%M:%S'))
        echo.infoln('Loading configuration...')
        self.__load_configuration()
        self.__device = DeviceProperties(self.__config.get())
        self.__all_devices = args.all
        device_input = [args.id]
        if (not device_input[0]) or (self.__all_devices):
            device_input = self.__device.list()
        for self.__id in device_input:
            error = False
            if self.__device.set(self.__id) is None:
                error = self.__id + ' not found in configuration file.'
            if not self.__device.is_enable() and not error:
                continue
            echo.infoln('Device...')
            echo.info('    ')
            if error:
                echo.erroln(error)
                sys.exit(True)
            echo.infoln(self.__device.info())
            echo.infoln('Project...')
            self.__firmware = Firmware(self.__device.get())
            echo.infoln(self.__firmware.info())
            echo.header(True)
            self.__firmware.verify()

    def upload(self):
        """
        description:
        """
        parser = argparse.ArgumentParser(
            prog=self.program_name + ' upload',
            description='upload firmware to device')
        parser.add_argument(
            '-i', '--id',
            required=True,
            help='device ID')
        parser.add_argument(
            '-d', '--date',
            action="store_true",
            help='display date')
        parser.add_argument(
            '-v', '--verbosity',
            type=int,
            default=3,
            choices=[0, 1, 2, 3, 4],
            help='verbose mode, options: ' +
            '0 Quiet, 1 Errors, 2 Warnings, 3 Info (default), 4 Debug')
        args = parser.parse_args(sys.argv[2:])
        echo.level(args.verbosity)
        echo.infoln(self.version)
        if args.date:
            echo.infoln('Started at: ' + time.strftime('%Y-%m-%d %H:%M:%S'))
        echo.infoln('Loading configuration...')
        self.__load_configuration()
        self.__device = DeviceProperties(self.__config.get())
        self.__id = args.id
        self.__device.set(self.__id)
        echo.infoln('Device...')
        echo.infoln(self.__device.info())
        echo.infoln('Project...')
        self.__firmware = Firmware(self.__device.get())
        echo.infoln(self.__firmware.info())
        echo.header(True)
        self.__session = Session(self.__device.get_comm())
        if not self.__session.is_connected():
            echo.erroln('Not connected.')
            sys.exit(True)
        self.__firmware.upload()

    def list(self):  # pylint: disable=too-many-branches,too-many-statements
        """
        description:
        """
        parser = argparse.ArgumentParser(
            prog=self.program_name + ' list',
            description='list devices')
        parser.add_argument(
            '-c', '--connected',
            default=False,
            action="store_true",
            help='show only connected devices')
        parser.add_argument(
            '-a', '--all',
            default=False,
            action="store_true",
            help='show even disabled devices')
        parser.add_argument(
            '-v', '--verbosity',
            type=int,
            default=4,
            choices=[0, 1, 2, 3, 4],
            help='verbose mode, options: ' +
            '0 Quiet, 1 Errors, 2 Warnings, 3 Info, 4 Debug (default)')
        args = parser.parse_args(sys.argv[2:])
        echo.level(args.verbosity)
        self.__all_devices = args.all
        self.__only_connected = args.connected
        self.__list()

    def __list(self):
        self.__load_configuration()
        device = DeviceProperties(self.__config.get())
        echo.warn(' Id\tName\tMark')
        echo.info('\tDescription')
        echo.debug('\t\tLink')
        echo.warnln('')
        echo.warn('------------------------')
        echo.info('------------------------')
        echo.debug('--------')
        echo.warnln('')
        for device_id in device.list():
            device.set(device_id)
            self.__session = Session(device.get_comm())
            # Ignore disable device
            if not self.__all_devices and not device.is_enable():
                continue
            # Ignore offline device
            interface_status = 'Serial' if self.__session.is_connected() else 'Offline'
            if self.__only_connected and (interface_status == 'Offline'):
                continue
            # Start displaying device information
            echo.erro(device_id)
            echo.warn("\t" +
                      device.system_plat + "\t" +
                      device.system_mark)
            system_desc = device.get_system()['desc']
            if len(system_desc) < 16:
                for _ in range(16-len(device.system_desc)):
                    system_desc += ' '
            echo.info('\t' + system_desc)
            echo.debug('\t' + interface_status)
            echo.erroln('')
        sys.exit(False)

    def __load_configuration(self):
        self.__config = File()
        self.__config.load(self.__config_file, 'json')


class Firmware:  # pylint: disable=too-many-instance-attributes
    """
    description:
    """

    def __init__(self, data):
        self.data = data
        self.__arduino_program = "arduino"
        self.__pylint = "pylint"
        self.platform = None
        self.mark = None
        self.description = None
        self.architecture = None
        self.system_path = None
        self.path = None
        self.system_work = None
        self.system_code = None
        self.system_logs = None
        self.arduino_file = None
        self.logs = None
        self.__device_path = None
        self.__device_speed = None
        self.terminal_echo = False
        self.terminal_end_of_line = 'LF'
        self.interface = 'serial'
        self.destination = ''
        self.__set()

    def __set(self):
        self.platform = self.data["system"].get("plat", self.platform)
        self.mark = self.data["system"].get("mark", self.mark)
        self.description = self.data["system"].get("desc", self.description)
        self.architecture = self.data["system"].get("arch", self.architecture)
        self.system_path = self.data["system"].get("path", self.system_path)
        self.path = os.path.join(os.environ['HOME'], self.system_path)
        self.arduino_file = self.path[self.path.rfind("/", 0):] + ".ino"
        self.system_work = self.data["system"].get("work", self.system_work)
        self.system_work = os.path.join(os.environ['HOME'], self.system_work)
        self.system_code = self.data["system"].get("code", self.system_code)
        self.system_logs = self.data["system"].get("logs", self.system_logs)
        self.logs = os.path.join(os.environ['HOME'], self.system_logs)
        self.__device_path = self.data["comm"]["serial"]\
            .get("path", self.__device_path)
        self.__device_speed = self.data["comm"]["serial"]\
            .get("speed", self.__device_speed)
        self.terminal_echo = self.data["comm"]["serial"]\
            .get("terminal_echo", self.terminal_echo)
        self.terminal_end_of_line = self.data["comm"]["serial"]\
            .get("terminal_end_of_line", self.terminal_end_of_line)
        self.interface = 'serial'
        if self.interface == 'serial':
            self.destination = os.popen("echo -n $(readlink -f " +
                                        self.__device_path + ")").read().rstrip()

    def __check(self):
        template = \
            {
                'comm': {
                    'serial': {
                        'path': 'string',
                        'speed': 'integer',
                        'delay': 'integer',
                        'terminal_echo': 'boolean',
                        'terminal_end_of_line': 'string'
                    }
                },
                'system': {
                    'arch': 'string',
                    'desc': 'string',
                    'logs': 'string',
                    'mark': 'string',
                    'path': 'string',
                    'work': 'string',
                    'plat': 'string'
                }
            }

    def info(self):
        """
        description:
        """
        return \
            '    Platform: ' + self.platform + '\n' + \
            '    Architecture: ' + self.architecture

    def verify(self):
        """
        description:
        """
        echo.infoln('Verifying...')
        # MicroPython
        if self.architecture == "MicroPython:ARM:PYBv1.1":
            cmd = 'find ' + self.system_work + ' -name "*.py" ' + \
                  '-exec ' + self.__pylint + ' {} \;'  # pylint: disable=anomalous-backslash-in-string
        # Arduino
        else:
            # Check if arduino program exists
            _check_program(self.__arduino_program)
            # Build command
            cmd = " --verify --board " + self.architecture + " " + \
                  self.path + "/" + self.arduino_file
            if echo.level() == 4:
                goma = self.__arduino_program + " --version 2> /dev/null"
                subprocess.call(goma, shell=True)
                cmd = " --verbose" + cmd
            cmd = self.__arduino_program + cmd
        if echo.level() < 3:
            cmd += " >/dev/null 2>&1"
        return_code = subprocess.call(cmd, shell=True)
        if return_code != 0:
            echo.erroln("Return code: " + str(return_code))
            if return_code > 127:
                return_code = 1
        echo.infoln('')
        return return_code

    def upload(self):
        """
        description:
        """
        echo.infoln('Uploading...')
        # MicroPython
        if self.architecture == "MicroPython:ARM:PYBv1.1":
            cmd = 'rsync \
                   --archive --delete --verbose --compress \
                   --exclude "*.md" \
                   --exclude "*.gnbs.conf" \
                   --exclude ".rsyncignore" \
                   --exclude "Pictures" \
                   ' + self.system_work + '/* ' + self.system_code + '/' + \
                   "; sync"
            echo.infoln("From: " + self.system_work, 1)
            echo.infoln("To: " + self.system_code, 1)
        # Arduino
        else:
            # Check if arduino program exists
            _check_program(self.__arduino_program)
            # Build command
            cmd = " --upload --board " + \
                  self.architecture + " " + \
                  self.path + "/" + self.arduino_file + \
                  " --port " + self.destination
            if echo.level() == 4:
                goma = self.__arduino_program + " --version 2> /dev/null"
                subprocess.call(goma, shell=True)
                cmd = " --verbose" + cmd
            cmd = self.__arduino_program + cmd
            echo.infoln("Communication device: " + self.destination.rstrip() + ".")
        if echo.level() < 3:
            cmd += " >/dev/null 2>&1"
        return_code = subprocess.call(cmd, shell=True)
        # Write buld number
        if return_code == 0:
            file_obj = open(self.logs + "/.buildno", 'r')
            buildno = file_obj.read()
            file_obj.close()
            if buildno == "":
                buildno = 1
            else:
                buildno = int(buildno) + 1
            file_obj = open(self.logs + "/.buildno", 'w')
            file_obj.write(str(buildno))
            echo.infoln("Build number: " + str(buildno))
        else:
            echo.erroln("Return code: " + str(return_code))
            if return_code > 127:
                return_code = 1
        echo.infoln('')
        return return_code


def _check_program(program):
    if _which(program) is None:
        echo.erroln('Program not found: ' + program)
        sys.exit(True)


def _which(program):
    def is_exe(fpath):
        return os.path.isfile(fpath) and os.access(fpath, os.X_OK)
    fpath = os.path.split(program)[0]
    if fpath:
        if is_exe(program):
            return program
    else:
        for path in os.environ["PATH"].split(os.pathsep):
            path = path.strip('"')
            exe_file = os.path.join(path, program)
            if is_exe(exe_file):
                return exe_file
    return None


def main():
    """
    description:
    """
    MakerAssist()


if __name__ == '__main__':
    main()
