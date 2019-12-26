"""
---
name: session.py
description: Device session package
copyright: 2016-2019 Marcio Pessoa
people:
  developers:
  - name: Marcio Pessoa
    email: marcio.pessoa@gmail.com
change-log:
  2019-09-03
  - version: 0.7
    fixed: String receive and parsing (only on Python 3).
  2019-01-08
  - version: 0.06
    fixed: Minor updated to support serial on Python 3.
  2017-07-27
  - version: 0.05b
    added: Featured colours to 'ok' and 'nok' received strings.
  2017-06-04
  - version: 0.04b
    added: Added comment parser to '()'
  2017-06-02
  - version: 0.03b
    added: Added comment parser to ';'
  2017-05-11
  - version: 0.02b
    added: Added is_ready() method.
    fixed: Added new line to send and receive screen output.
    added: Added command string filter in send() method.
  2017-02-21
  - version: 0.01b
    added: Added information messages.
  2016-02-19
  - version: 0.00b
    added: Scrach version.
"""

import sys
import os.path
import os
import re
from time import sleep
from socket import gethostbyname
import serial


class Session:  # pylint: disable=too-many-instance-attributes,too-many-public-methods
    """
    description:
    """

    __version__ = 0.7

    def __init__(self, data):
        self.interface = None
        self.data = None
        self.gcode = None
        self.comm_serial_path = ''
        self.comm_serial_speed = 0
        self.comm_serial_terminal_echo = True
        self.comm_serial_terminal_end_of_line = 'CRLF'
        self.comm_serial_delay = 0
        self.comm_network_address = None
        self.retry = 3  # times
        self.timeout = 100  # milliseconds
        self.session = None
        self.reset()
        self.load(data)

    def reset(self):
        """
        description:
        """
        self.data = None
        self.comm_serial_path = ''
        self.comm_serial_speed = 0
        self.comm_serial_terminal_echo = True
        self.comm_serial_terminal_end_of_line = 'CRLF'
        self.comm_serial_delay = 0
        self.comm_network_address = None
        self.retry = 3  # times
        self.timeout = 100  # milliseconds

    def load(self, data):
        """
        description:
        """
        if data == []:
            return None
        self.data = data
        # Optional keys
        try:
            self.comm_serial_path = \
                self.data["serial"].get('path', self.comm_serial_path)
            self.comm_serial_speed = \
                self.data["serial"].get('speed', self.comm_serial_speed)
            self.comm_serial_delay = \
                self.data["serial"].get('delay', self.comm_serial_delay)
            self.comm_serial_terminal_echo = \
                self.data["serial"].get('terminal_echo', self.comm_serial_terminal_echo)
            self.comm_serial_terminal_end_of_line = \
                self.data["serial"].get('terminal_end_of_line',
                                        self.comm_serial_terminal_end_of_line)
        except KeyError:
            pass
        # Network configuration
        try:
            self.comm_network_address = (
                self.data["network"].get('address', self.comm_network_address))
            # Get IP address from host name
            self.comm_network_address = gethostbyname(self.comm_network_address)
        except BaseException:
            pass
        return 0

    def is_connected(self):
        """
        description:
        """
        if self.is_connected_serial():
            return True
        return False

    def is_connected_serial(self):
        """
        description:
        """
        return os.path.exists(self.comm_serial_path)

    def stop(self):
        """
        description:
        """
        if self.session:
            self.session.close()
        self.reset()

    def start(self):
        """
        description:
        """
        if not self.data:
            return None
        # echo.infoln("Connecting...", 1)
        if self.is_connected_serial():
            try:
                self.session = serial.Serial()
                self.session.port = self.comm_serial_path
                self.session.baudrate = self.comm_serial_speed
                self.session.timeout = 1
                self.session.open()
            except BaseException:
                # echo.warnln('Operation not completed.', 2)
                return False
            sleep(self.comm_serial_delay / 1000)
            # echo.infoln('Speed: ' + str(self.comm_serial_speed) + ' bps', 2)
            return self.session
        # echo.warnln('Device is not connected.', 2)
        return True

    def info(self):
        """
        description:
        """
        # echo.infoln('Session...')
        if not self.data:
            return
        # if self.comm_serial_path is not None:
            # echo.infoln('Startup delay: ' + str(self.comm_serial_delay) + ' ms', 1)
            # echo.infoln('Serial: ' + str(self.comm_serial_path), 1)
        # if self.comm_network_address is not None:
            # echo.infoln('Network: ' + str(self.comm_network_address), 1)

    def run(self):
        """
        description:
        """
        # echo.infoln('Running program...')
        go_on = False
        while not go_on:
            go_on = self.is_ready()
        lines = len(self.gcode)
        counter = 0
        while True:
            if go_on:
                if counter == lines:
                    break
                line = self.gcode[counter]
                counter += 1
                if self.send(line):
                    continue
            received = self.receive()
            go_on = bool(re.search('ok', str(received)))

    def is_ready(self):
        """
        description:
        """
        i = 0
        while True:
            content = self.receive()
            if content is False:
                i += 1
            else:
                i = 0
            if i > 1:
                break
        return True

    def play(self):  # pylint: disable=no-self-use
        """
        description:
        """
        return False

    def pause(self):  # pylint: disable=no-self-use
        """
        description:
        """
        return False

    def send_expect(self, command, expected, timeout=0, retry=0):
        """Send a command and receive a message.

        Retrieves rows pertaining to the given keys from the Table
        instance represented by big_table.  Silly things may happen if
        other_silly_variable is not None.

        Args:
            command:
            expected:
                A list with three items:
                [0] Header
                    - Description: Field used to start a message.
                    - Default value: This is a required field.
                [1] Payload
                    - Description: Message content.
                                   Also kown as data field.
                    - Default value: This is a required field.
                [2] Trailer
                    - Description: Control field used to identify end of
                                   message.
                                   Also known as footer field.
                    - Default value: '\n'
            timeout:
            retry:

        Returns:
            A dict mapping keys to the corresponding table row data
            fetched. Each row is represented as a tuple of strings. For
            example:

            {'Serak': ('Rigel VII', 'Preparer'),
             'Zim': ('Irk', 'Invader'),
             'Lrrr': ('Omicron Persei 8', 'Emperor')}

            If a key from the keys argument is missing from the dictionary,
            then that row was not found in the table.

        Raises:
            IOError: An error occurred accessing the bigtable.Table object.
        """
        if retry == 0:
            retry = self.retry
        if timeout == 0:
            timeout = self.timeout
        try:
            self.send(command)
        except IOError:
            return True
        serial_line = ""
        for _ in range(retry):
            sleep(int((timeout) / 1000))
            serial_line += self.receive()
            if expected in serial_line:
                return serial_line
        # echo.erro("Command return lost.")
        return True

    def receive(self):
        """
        description: Just receive a message
        """
        try:
            received = self.session.readline().rstrip()
            received = str(received, 'utf-8')
        except IOError:
            return True
        if received == "":  # or received == "\n" or received == "\r":
            return False
        # Change color based on device response ('ok' or 'nok')
        if re.search('nok', str(received)):
            # echo.codeln(received, 'red', attrs=['bold'])
            return received
        if re.search('ok', str(received)):
            # echo.codeln(received, 'green', attrs=['bold'])
            return received
        return received

    def send(self, command):
        """
        description: Just send a message
        """
        # Store comments
        try:
            comment = command[re.search(';', command).span()[0]:]
        except BaseException:
            comment = ''
        if comment == '':
            try:
                comment = command[re.search('\(', command).span()[0]:]  # pylint: disable=anomalous-backslash-in-string
            except BaseException:
                comment = ''
        # Remove comments
        command = re.sub(r'(?:_a)?\(([^(]*)$', '\n', command)
        command = re.sub(r'(?:_a)?\;([^;]*)$', '\n', command)
        # Trim start and end spaces
        command = command.strip(' ').rstrip()
        comment = comment.strip(' ').rstrip()
        # Ignore blank lines
        if command == '':
            # if comment != '':
                # echo.codeln(comment)
            return True
        # echo.code(command, attrs=['bold'])
        # echo.codeln('  ' + comment)
        try:
            self.session.write((command + '\n').encode())
        except IOError:
            return True
        return False

    def send_wait(self, command):
        """
        description:
        """
        self.send(command)
        while True:
            received = self.receive()
            if re.search('ok', str(received)):
                break

    def set_retry(self, retry):
        """
        description: Set default number of retries
        """
        self.retry = retry

    def set_timeout(self, timeout):
        """
        description: Set default timeout value
        """
        self.timeout = timeout

    def clear(self):
        """
        description: Clear message buffer
        """
        while self.receive():
            continue

    def set_program(self, data):
        """
        description: Set G-Code
        """
        if not data or data == '':
            # echo.erroln('Invalid G-code file.')
            sys.exit(True)
        self.gcode = data
