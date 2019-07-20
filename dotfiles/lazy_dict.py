class LazyDict(dict):
    """
    A version of dict where a user-supplied factory method can be used to
    provide None-marked elements.
    """

    def __init__(self, factory):
        super().__init__()
        self.factory = factory

    def __getitem__(self, key):
        it = super().__getitem__(key)
        if it is None:
            print(">>>>>> Factory for", key)
            it = self.factory(key)
            self[key] = it
        return it
