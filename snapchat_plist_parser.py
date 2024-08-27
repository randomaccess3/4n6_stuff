import nska_deserialize as nd

# Extracts the share_user bplist, whatever that is?

def parse_data(fullpath):
    try:
        deserialized_plist = nd.deserialize_plist(fullpath, full_recurse_convert_nska=True)
        share_user = deserialized_plist['share_user']
        sections = share_user['SECTIONS']
        for s in sections:
            s_title = s['SECTION_TITLE']
            friend_name = friend_display = ""
            destinations = s['DESTINATIONS']
            for d in destinations:
                keys = d.keys()
                if 'FRIEND_DISPLAY' in keys:
                    friend_name = d['FRIEND_NAME']
                    friend_display = d['FRIEND_DISPLAY']
                    print (s_title, " - ", friend_display, " - ", friend_name)
                else:
                    print ("Group stuff I don't pull out")
                    

    except (nd.DeserializeError, 
            nd.biplist.NotBinaryPlistException, 
            nd.biplist.InvalidPlistException,
            nd.plistlib.InvalidFileException,
            nd.ccl_bplist.BplistError, 
            ValueError, 
            TypeError, OSError, OverflowError) as ex:
        # These are all possible errors from libraries imported

        print('Had exception: ' + str(ex))
        deserialized_plist = None
    return

def main():
    plistname = "group.snapchat.picaboo.plist"
    parse_data(plistname)

if __name__ == "__main__":
    main()


