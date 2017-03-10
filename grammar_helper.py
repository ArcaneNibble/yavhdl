#!/usr/bin/python3 -i

# Load stuff
forward_graph = {}
reverse_graph = {}
inf = open("vhdl_grammar.dot", 'r')
for l in inf.readlines():
    if "->" in l:
        l = l.strip()
        head, tail = l.split("->")
        head = head.strip()
        tail = tail.strip()
        if tail[-1] == ";":
            tail = tail[:-1]

        if head not in forward_graph:
            forward_graph[head] = set()
        if tail not in reverse_graph:
            reverse_graph[tail] = set()

        forward_graph[head].add(tail)
        reverse_graph[tail].add(head)

def bfs(graph, start, limit):
    visited = set()
    todo = set()

    todo.add((start, 0))

    while todo:
        node, depth = todo.pop()
        if limit != -1 and depth == limit:
            continue

        indent = depth
        if node in visited:
            continue

        if node not in graph:
            continue

        print("\n" + " " * indent + node + " ->")
        visited.add(node)

        next_nodes = graph[node]
        for next_node in next_nodes:
            print(" " * (indent + 1) + next_node)
            todo.add((next_node, indent + 1))

        indent += 1

def fwd(start, limit=-1):
    bfs(forward_graph, start, limit)

def back(start, limit=-1):
    bfs(reverse_graph, start, limit)
