"""
---
name: device.py
description: Device package
copyright: 2016-2019 Marcio Pessoa
people:
  developers:
  - name: Marcio Pessoa
    email: marcio.pessoa@gmail.com
change-log:
  2019-09-07
  - version: 0.13
    fixed: Adequation to pylint.
  2019-02-12
  - version: 0.12
    fixed: Auto detection was returning always the last device.
  2019-01-25
  - version: 0.11b
    fixed: Auto detection was returning invalid device name.
  2018-04-02
  - version: 0.10b
    changed: Only configured interfaces are shown.
  2018-02-11
  - version: 0.09b
    added: is_enable method.
  2017-06-06
  - version: 0.08b
    added: Terminal line feed and carriage return customization.
    added: Terminal local echo customization.
  2017-06-06
  - version: 0.07b
    changed: Removed Warning messages.
  2017-05-11
  - version: 0.06b
    added: Added startup() method.
  2017-05-08
  - version: 0.05b
    added: Added presentation() method.
  2017-04-01
  - version: 0.04b
    changed: Added version information.
  2017-02-22
  - version: 0.03b
    changed: Removed method DeviceProperties.items_extended().
    added: Method DeviceProperties.is_network_connected().
  2017-02-21
  - version: 0.02b
    added: Information messages.
    added: Verbose error messages.
  2017-02-20
  - version: 0.01b
    added: Changed except ',' to 'as' to addopt Python 3 style.
  2016-05-12
  - version: 0.00b
    added: first version.
"""

import sys
from tools.session import Session


class DeviceProperties:  # pylint: disable=too-many-instance-attributes
    """
    description:
    """

    __version__ = 0.13

    def __init__(self, data):
        self.version = 0.13
        self.__id = None
        self.interface = None
        self.system_plat = None
        self.system_mark = None
        self.system_desc = None
        self.system_arch = None
        self.system_path = None
        self.system_work = None
        self.system_logs = None
        self.load(data)
        self.reset()

    def load(self, data):
        """
        description:
        """
        self.data = data

    def is_enable(self):
        """
        description:
        """
        enable = False
        try:
            enable = self.data["device"][self.__id].get('enable', True)
        except BaseException:
            pass
        return enable

    def get_id(self):
        """
        description:
        """
        return self.__id

    def set(self, device_id):
        """Set a device to be used.

        Used to set a device and import all elements.

        Attributes:
            element: An element name (like x1, x2, x6, etc.).
        """
        if not device_id:
            return
        self.__id = device_id
        # Is device present in configuration file?
        # try:
            # echo.check_id = self.data["device"][self.__id]
        # except KeyError:
            # echo.erroln('Device is not present in configuration file.')
            # sys.exit(True)
        # Check mandatory keys.
        try:
            self.system_plat = self.data["device"][self.__id]["system"]["plat"]
            self.system_mark = self.data["device"][self.__id]["system"]["mark"]
            self.system_desc = self.data["device"][self.__id]["system"]["desc"]
            self.system_arch = self.data["device"][self.__id]["system"]["arch"]
            self.system_path = self.data["device"][self.__id]["system"]['path']
            self.system_work = self.data["device"][self.__id]["system"]['work']
            self.system_logs = self.data["device"][self.__id]["system"]['logs']
        except KeyError: # as err:
            # echo.erroln('Mandatory key is absent: %s' % (err))
            sys.exit(True)

    def list(self):
        """Fetches device IDs from a dictionary.

        Args:
            None

        Returns:
            A list of device IDs. For example:

            ['x1', 'x2', 'x3', 'x4']

        Raises:
            None
        """
        elements = []
        for i in self.data["device"]:
            elements.append(i)
        elements.sort()
        return elements

    def get(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]
        except BaseException:
            return []

    def get_comm(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]["comm"]
        except BaseException:
            return []

    def get_objects(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]["object"]
        except BaseException:
            return []

    def get_endup(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]["endup"]
        except BaseException:
            return []

    def get_startup(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]["startup"]
        except BaseException:
            return []

    def get_control(self):
        """
        description:
        """
        try:
            return self.data["device"][self.__id]["control"]
        except BaseException:
            return []

    def reset(self):
        """Reset device default properties"""
        self.__id = None
        self.system_plat = ""
        self.system_mark = ""
        self.system_desc = ""
        self.system_arch = ""
        self.system_path = ""
        self.system_logs = ""

    def set_interface(self, interface):
        """
        description:
        """
        self.interface = interface

    def info(self):
        """
        description:
        """
        if not self.__id:
            return None
        return \
            '    ID: ' + str(self.__id) + '\n' + \
            '    Name: ' + str(self.system_plat) + ' ' + \
            'Mark ' + str(self.system_mark) + '\n' + \
            '    Description: ' + str(self.system_desc)

    def detect(self):
        """
        description:
        """
        self.reset()
        ids = []
        for device_id in self.list():
            self.set(device_id)
            session = Session(self.get_comm())
            if not self.is_enable():
                continue
            if session.is_connected_serial():
                ids.append(str(device_id).encode("utf-8"))
            else:
                session.reset()
            self.reset()
        devices = len(ids)
        if devices == 1:
            self.set(ids[0].decode('utf-8'))
        elif devices < 1:
            self.set(None)
        elif devices > 1:
            self.set(False)
        return ids
