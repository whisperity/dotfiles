class LazyDict(dict):
    """
    A version of dict where a user-supplied factory method can be used to
    provide None-marked elements.

    :note: Why doesn't collections.defaultdict support this... :(
    """

    def __init__(self, factory, initial_keys=None):
        """
        Create a new dict and register the element factory in it.

        :param initial_keys: (Optional) if a collection, set the given keys in
            the dict to None.
        """
        super().__init__()
        self.factory = factory

        for key in initial_keys if initial_keys else []:
            self.__setitem__(key, None)

    def __getitem__(self, key):
        """
        Returns the element for the given key, as if D[key] was called, but if
        the element was None, performs construction with the set factory
        method.

        If `key` isn't part of the dict, raises the same `KeyError` as a normal
        dict would.
        """
        it = super().__getitem__(key)
        if it is None:
            it = self.factory(key)
            self[key] = it
        return it
