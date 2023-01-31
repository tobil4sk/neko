# Taken from MSYS Mingw packages
file(
	DOWNLOAD https://raw.githubusercontent.com/msys2/MINGW-packages/b3095dc5ba1f6b8d04807520a30fb0ec98731f04/mingw-w64-apr/apr_wtypes.patch
	EXPECTED_HASH SHA256=b82dd98ec8cff2273fb071dc9f1d2ee7466905c9b82a12d3d83ce1cb5920a5d6
	apr_wtypes.patch
)

file(
	DOWNLOAD https://raw.githubusercontent.com/msys2/MINGW-packages/ab2da3553ae2a6712662edce547114afcd9020b4/mingw-w64-apr/apr_ssize_t.patch
	EXPECTED_HASH SHA256=ba7d6de7e7930801df483d444b97c159af4ff11b4ce27e1337aea5e0417e6066
	apr_ssize_t.patch
)

# Required to fix a preprocessor error on MINGW
file(
	DOWNLOAD http://svn.apache.org/viewvc/apr/apr/trunk/include/apr_version.h?r1=731056&r2=983400&view=patch
	EXPECTED_HASH SHA256=d4cc7b7c53e859f4ec1dc624b3b2271c423d7a74f05926019b834e54ea1e78ea
	apr_version.patch
)

execute_process(
	COMMAND patch -p0 --forward -i apr_ssize_t.patch
	COMMAND patch -p0 --forward -i apr_wtypes.patch
	COMMAND patch -p3 --forward -i apr_version.patch
	WORKING_DIRECTORY ${apr_source}
)
