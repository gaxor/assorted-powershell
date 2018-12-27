Enum Fruit

{
    Apple = 29
    Pear = 30
    Kiwi = 31
}

Enum MoreFruit

{
    Papple = [fruit]::Pear + [fruit]::Apple
    Kapple = [fruit]::Kiwi + [fruit]::Apple
    KaPapple = [fruit]::Kiwi + [fruit]::Pear + [fruit]::Apple
}

[fruit]::Apple
[morefruit]::KaPapple