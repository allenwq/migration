# Allow open_uri to redirect http to https
def OpenURI.redirectable?(uri1, uri2)
  uri1.scheme.downcase == uri2.scheme.downcase ||
    (/\A(?:http|ftp|https)\z/i =~ uri1.scheme && /\A(?:http|ftp|https)\z/i =~ uri2.scheme)
end
