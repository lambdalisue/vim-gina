import sys

if sys.version_info >= (3, 0):
    name = input('Please input your name: ')
else:
    name = raw_input('Please input your name: ')
print('Hello %s' % name)
