# https://jira.mariadb.org/browse/CONC-174
set(cmakelists ${mariadb_source}/CMakeLists.txt)

file(READ ${cmakelists} content)

# do not use replace /MD with /MT
string(REPLACE
	"STRING(REPLACE \"/MD\" \"/MT\" COMPILER_FLAGS \${COMPILER_FLAGS})"
	"# STRING(REPLACE \"/MD\" \"/MT\" COMPILER_FLAGS \${COMPILER_FLAGS})"
	content ${content}
)

file(WRITE ${cmakelists} ${content})

set(cmakelists ${mariadb_source}/cmake/ConnectorName.cmake)

file(READ ${cmakelists} content)

# Fix broken syntax on newer CMake
string(REPLACE
	"  END()"
	"  ENDIF()"
	content ${content}
)

file(WRITE ${cmakelists} ${content})

if(MINGW)
	# requires extra patches to get it working for mingw
	# based on the AUR package: https://aur.archlinux.org/packages/mingw-w64-mariadb-connector-c

	file(
		DOWNLOAD https://aur.archlinux.org/cgit/aur.git/plain/0001-Fix-mingw-w64-build.patch?h=mingw-w64-mariadb-connector-c&id=8e921a79096a0727c43d0514d4fb9c1084b48762
		EXPECTED_HASH SHA256=148983c92018f684f6e351e23b273ab3f4f2a51a5e65bce6150c0ddd8dc30654
		0001-Fix-mingw-w64-build.patch
	)
	file(
		DOWNLOAD https://aur.archlinux.org/cgit/aur.git/plain/0002-Enable-pkg-config-for-mingw-w64-build.patch?h=mingw-w64-mariadb-connector-c&id=8e921a79096a0727c43d0514d4fb9c1084b48762
		EXPECTED_HASH SHA256=6bd3ed4c80a2756cc59129011b95e67cacb3b64832b48b9898aa5cb44dab6214
		0002-Enable-pkg-config-for-mingw-w64-build.patch
	)

	execute_process(
		COMMAND patch -p1 --forward -i 0001-Fix-mingw-w64-build.patch
		COMMAND patch -p1 --forward -i 0002-Enable-pkg-config-for-mingw-w64-build.patch
		WORKING_DIRECTORY ${mariadb_source}
	)
endif()
