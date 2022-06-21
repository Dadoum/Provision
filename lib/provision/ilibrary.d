module provision.ilibrary;

interface ILibrary {
    void* load(string symbol) const;
}
