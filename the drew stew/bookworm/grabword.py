import random

with open('keywords.txt') as f, open('fillwords.txt') as g:

    keywords = f.read().splitlines()
    fillwords = g.read().splitlines()

    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    RESET = '\033[0m'

    i = 0
    while (i <= 400):
        keyword = random.choice(keywords)
        fillword = random.choice(fillwords)[::-1]
        choices = [keyword, fillword]
        word = random.choices(choices, weights=[1, 9])[0]
        if word == "wisdom":
            print(f"{BLUE}", end="")
        if word == "flip":
            print(f"{GREEN}", end="")
        if word == "trapped":
            print(f"{RED}", end="")
        if word == "instinct":
            print(f"{YELLOW}", end="")
        for letter in word:
            print(letter, end=" ")
        print(f"{RESET}", end="")
        i+=1