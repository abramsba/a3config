import re
import time
import pymysql

error       = open('error.log', 'w')
cfg_dump    = "file\\path\\to\\dump.cfg"
class_regex = r'class ([\w\d]+)(:? ([\w\d]+)|)( ({};))?'
attr_regex  = r'^([\S]+) = (.+);$'
connection  = pymysql.connect(
        host='localhost',
        user='',
        db='',
        password='',
        autocommit=True)

class Stack:
  def __init__(self):
    self.__storage = []
    self.__pushes = 0;
  def isEmpty(self):
    return len(self.__storage) == 0
  def top(self):
    return self.__storage[-1]
  def push(self,p):
    self.__storage.append(p)
    self.__pushes = self.__pushes + 1
  def pop(self):
    return self.__storage.pop()
  def length(self):
    return len(self.__storage)
  def pushes(self):
    return self.__pushes

def insertClass(class_name, class_id, parent_name, parent_id, inherit_name):
    stmt = "insert into classes (name, id, parent, pid, inherit) values (%s, %s, %s, %s, %s)"
    cr = connection.cursor()
    try:
      cr.execute(stmt, (class_name, class_id, parent_name, parent_id, inherit_name))
    except Exception:
      error.write("%s\n" % (stmt % (class_name, str(class_id), parent_name, str(parent_id), inherit_name)))
    cr.close()

def insertAttr(class_name, class_id, attr_name, attr_value):
    stmt = "insert into attributes (classname, classid, attribute, value) value (%s, %s, %s, %s)"
    cr = connection.cursor()
    try:
      cr.execute(stmt, (class_name, class_id, attr_name, attr_value))
    except Exception:
      error.write("%s\n" % (stmt % (class_name, str(class_id), attr_name, attr_value)))
    cr.close()

stack = Stack()
start = int(round(time.time() * 1000))
with open(cfg_dump, encoding="utf8") as f:
    for line in f:
        stripped = line.strip()
        if re.match( class_regex, stripped ):
            results = re.search(class_regex, stripped)
            parent_name = ""
            parent_id = -1
            if stack.length() > 0:
                parent_name = stack.top()[0]
                parent_id   = stack.top()[1]
            class_name = results.group(1)
            class_id = stack.pushes()
            inherit_name = results.group(3) if results.group(3) != None else ""
            insertClass(class_name.encode('utf-8'), int(class_id), parent_name.encode('utf-8'), int(parent_id), inherit_name.encode('utf-8'))
            something = results.group(5)
            if something == None:
                stack.push([class_name, class_id])
        else:
            if stripped == '{':
                continue
            elif stripped == '};':
                class_name = stack.top()[0]
                class_id = stack.top()[1]
                stack.pop()
            elif re.match( attr_regex, stripped ):
                attr_res = re.search(attr_regex, stripped)
                class_name = stack.top()[0]
                class_id = stack.top()[1]
                attr_name = attr_res.group(1)
                attr_value = attr_res.group(2)
                insertAttr(class_name.encode('utf-8'), int(class_id), attr_name.encode('utf-8'), attr_value.encode('utf-8'))

finish = int(round(time.time() * 1000))
print("Duration: %d" % int(finish - start))
print("Stack size: %d" % stack.length())

error.close()
connection.close()



