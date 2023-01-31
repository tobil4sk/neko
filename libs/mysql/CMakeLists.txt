
######################
# OpenSSL

if (STATIC_OPENSSL)
	if (APPLE)
		if (${CMAKE_OSX_ARCHITECTURES} STREQUAL "i386")
			set(OPENSSL_CONF ./Configure darwin-i386-cc "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
		elseif (${CMAKE_OSX_ARCHITECTURES} STREQUAL "x86_64")
			set(OPENSSL_CONF ./Configure darwin64-x86_64-cc "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
		endif()
	elseif (WIN32)
		find_package(Perl REQUIRED)

		if(MINGW)
			if (arch_64)
				set(openssl_target mingw64)
			else()
				set(openssl_target mingw)
			endif()
		else()
			set(OPENSSL_MAKE_COMMAND nmake /S)
			if (arch_64)
				set(openssl_target VC-WIN64A)
			else()
				set(openssl_target VC-WIN32)
			endif()
		endif()

		set(OPENSSL_CONF ${PERL_EXECUTABLE} Configure ${openssl_target} no-asm)
	else()
		set(OPENSSL_CONF ./config)
	endif()

	if (WIN32 AND NOT MINGW)
		set(OPENSSL_MAKE_COMMAND nmake /S)
	else()
		set(OPENSSL_MAKE_COMMAND make)
	endif()

	set(OPENSSL_CONFS
		CONFIGURE_COMMAND cd ${CMAKE_BINARY_DIR}/libs/src/openssl &&
			${OPENSSL_CONF} no-tests --prefix=${CMAKE_BINARY_DIR}/libs/src/install-prefix
		BUILD_COMMAND cd ${CMAKE_BINARY_DIR}/libs/src/openssl &&
			${OPENSSL_MAKE_COMMAND}
		INSTALL_COMMAND cd ${CMAKE_BINARY_DIR}/libs/src/openssl &&
			${OPENSSL_MAKE_COMMAND} install_sw
	)

	ExternalProject_Add(OpenSSL
		${EP_CONFIGS}
		URL https://www.openssl.org/source/old/1.1.1/openssl-1.1.1.tar.gz
		URL_MD5 7079eb017429e0ffb9efb42bf80ccb21
		${OPENSSL_CONFS}
		PATCH_COMMAND ${CMAKE_COMMAND} -Dopenssl_source=${CMAKE_BINARY_DIR}/libs/src/openssl -P ${CMAKE_SOURCE_DIR}/cmake/patch_openssl.cmake
		SOURCE_DIR ${CMAKE_BINARY_DIR}/libs/src/openssl
	)
	set_target_properties(OpenSSL PROPERTIES ${EP_PROPS})
	if (MINGW)
		set(OPENSSL_LIBRARIES
			Crypt32
			${CMAKE_BINARY_DIR}/libs/src/install-prefix/lib/libcrypto.dll.a
			${CMAKE_BINARY_DIR}/libs/src/install-prefix/lib/libssl.dll.a
		)
	elseif(WIN32)
		set(OPENSSL_LIBRARIES
			Crypt32
			${CMAKE_BINARY_DIR}/libs/src/install-prefix/lib/libcrypto.lib
			${CMAKE_BINARY_DIR}/libs/src/install-prefix/lib/libssl.lib
		)
	endif()
	# Download project for fat source archive
	add_dependencies(download_deps OpenSSL-download)
else()
	find_package(OpenSSL)
endif()

######################
# mysql.ndll

add_library(mysql.ndll MODULE mysql.c)

if (STATIC_MARIADBCONNECTOR)
	if (STATIC_OPENSSL AND (NOT WIN32 OR MINGW))
		set(OPENSSL_CONF -DOPENSSL_ROOT_DIR=${CMAKE_BINARY_DIR}/libs/src/install-prefix)
		set(OPENSSL_DEP OpenSSL)
	elseif()
		set(OPENSSL_CONF "")
		set(OPENSSL_DEP "")
	endif()
	if (WIN32 AND NOT MINGW)
		set(MARIADB_CONNECTOR_LIBRARIES
			${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector-build/libmariadb/${CMAKE_CFG_INTDIR}/mariadbclient.lib
		)
	else()
		set(MARIADB_CONNECTOR_LIBRARIES
			${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector-build/libmariadb/libmariadbclient.a
		)
	endif()
	if (WIN32)
		list(PREPEND MARIADB_CONNECTOR_LIBRARIES ${OPENSSL_LIBRARIES})
	endif()
	ExternalProject_Add(MariaDBConnector
		${EP_CONFIGS}
		DEPENDS ${OPENSSL_DEP}
		URL https://downloads.mariadb.com/Connectors/c/connector-c-3.3.1/mariadb-connector-c-3.3.1-src.tar.gz
		URL_HASH SHA256=29993f4ae4c975662724978792d1a503b9ee760fbb194d321a754253cbe60aad
		CMAKE_ARGS
			-Wno-dev
			-DCMAKE_OSX_ARCHITECTURES=${CMAKE_OSX_ARCHITECTURES}
			-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}
			-DWITH_SSL=ON
			${OPENSSL_CONF}
		PATCH_COMMAND
			${CMAKE_COMMAND}
				-Dmariadb_source=${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector
				-DMINGW=${MINGW}
				-P ${CMAKE_SOURCE_DIR}/cmake/patch_mariadb.cmake
				--trace
		BUILD_COMMAND cd ${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector-build &&
			${CMAKE_COMMAND} --build . --target mariadbclient --config ${CMAKE_CFG_INTDIR}
		INSTALL_COMMAND echo skip install
		BUILD_BYPRODUCTS ${MARIADB_CONNECTOR_LIBRARIES}
	)
	set_target_properties(MariaDBConnector PROPERTIES ${EP_PROPS})
	set(MARIADB_CONNECTOR_INCLUDE_DIR
		${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector/include
		${CMAKE_BINARY_DIR}/libs/src/MariaDBConnector-build/include
	)
	add_dependencies(mysql.ndll MariaDBConnector)
	# Download project for fat source archive
	add_dependencies(download_deps MariaDBConnector-download)
else()
	find_package(MariaDBConnector REQUIRED)
endif()

target_include_directories(mysql.ndll
	PRIVATE
	${MARIADB_CONNECTOR_INCLUDE_DIR}
)

target_link_libraries(mysql.ndll libneko ${MARIADB_CONNECTOR_LIBRARIES})

if (WIN32)
	# target_link_libraries(mysql.ndll ws2_32 crypt32 shlwapi Secur32)
	target_link_libraries(mysql.ndll ws2_32 crypt32 shlwapi secur32 kernel32)
endif()

set_target_properties(mysql.ndll
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME mysql
	SUFFIX .ndll
)

if(APPLE)
	set_target_properties(mysql.ndll
		PROPERTIES
		LINK_FLAGS "-undefined dynamic_lookup ${LINK_FLAGS}"
	)
endif(APPLE)

######################
# mysql5.ndll

add_library(mysql5.ndll MODULE
	my_proto/my_proto.c
	my_proto/my_api.c
	mysql.c
)

target_include_directories(mysql5.ndll
	PRIVATE
	${CMAKE_CURRENT_SOURCE_DIR}/my_proto
)

target_link_libraries(mysql5.ndll
	socket
	sha1
	libneko
)

if (WIN32)
	target_link_libraries(mysql5.ndll ws2_32)
endif()

set_target_properties(mysql5.ndll
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME mysql5
	SUFFIX .ndll
)

install (
	TARGETS mysql.ndll mysql5.ndll
	DESTINATION ${DEST_NDLL}
)

install(SCRIPT ${NEKO_FLATTEN_SCRIPT})
