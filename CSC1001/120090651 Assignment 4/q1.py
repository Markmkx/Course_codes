class Node:
    def __init__(self, element, pointer):
        self.element = element
        self.pointer = pointer

class SinglyLinkedList:
    def __init__(self, head = None):
        self.head = head
        self.size = 0

    def insert(self, data):
        firstdata = Node(data, None)
        firstdata.pointer = self.head
        self.head = firstdata
        
    def recursive_count(self, node, count = 0):
        if node == None:
            return count
        else:
            count += 1
            return self.recursive_count(node.pointer, count)

def main():
    LinkedList = SinglyLinkedList()
    for i in range(4):
        LinkedList.insert(i)
    count = LinkedList.recursive_count(LinkedList.head)
    print("The length of the list is '%s'"% count)

main()