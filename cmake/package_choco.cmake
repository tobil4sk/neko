find_package(Git REQUIRED)

# format CHOCO_VERSION
if(DEFINED ENV{TAG_RELEASE})
	set(CHOCO_VERSION ${NEKO_VERSION})
else()
	execute_process(
		COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
		OUTPUT_VARIABLE COMMIT_SHA
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	execute_process(
		COMMAND ${GIT_EXECUTABLE} show -s --format=%cI HEAD
		OUTPUT_VARIABLE COMMIT_TIME
		OUTPUT_STRIP_TRAILING_WHITESPACE
	)
	string(SUBSTRING ${COMMIT_TIME} 0 19 COMMIT_TIME)
	string(REGEX REPLACE [^0-9] "" COMMIT_TIME ${COMMIT_TIME})
	set(CHOCO_VERSION ${NEKO_VERSION}-SNAP${COMMIT_TIME})
endif()

message(STATUS "building package version ${CHOCO_VERSION} using ${bin_archive}")


get_filename_component(bin_archive_dir ${bin_archive} DIRECTORY)

execute_process(
	COMMAND ${CMAKE_COMMAND} -E tar x ${bin_archive}
	WORKING_DIRECTORY ${bin_archive_dir}
)

configure_file(
	${source_dir}/extra/neko.nuspec
	${bin_archive_dir}/${bin_archive_name_we}/neko.nuspec
	@ONLY
)
configure_file(
	${source_dir}/extra/chocolatey/chocolateyInstall.ps1
	${bin_archive_dir}/${bin_archive_name_we}/chocolateyInstall.ps1
	@ONLY
)
configure_file(
	${source_dir}/extra/chocolatey/chocolateyUninstall.ps1
	${bin_archive_dir}/${bin_archive_name_we}/chocolateyUninstall.ps1
	@ONLY
)
configure_file(
	${source_dir}/LICENSE
	${bin_archive_dir}/${bin_archive_name_we}/LICENSE
	@ONLY
)
configure_file(
	${source_dir}/extra/chocolatey/VERIFICATION.txt
	${bin_archive_dir}/${bin_archive_name_we}/VERIFICATION.txt
	@ONLY
)
execute_process(
	COMMAND choco pack
	WORKING_DIRECTORY ${bin_archive_dir}/${bin_archive_name_we}
)

file(GLOB nupkg
	${bin_archive_dir}/${bin_archive_name_we}/*.nupkg
)

get_filename_component(nupkg_name ${nupkg} NAME)
message(STATUS "created ${nupkg_name}")

file(COPY ${nupkg} DESTINATION ${bin_archive_dir})

file(REMOVE_RECURSE ${bin_archive_dir}/${bin_archive_name_we})

if(DEFINED ENV{APPVEYOR})
	message(STATUS "pushing ${nupkg_name} to AppVeyor feeds")
	execute_process(
		COMMAND appveyor PushArtifact ${nupkg_name}
		WORKING_DIRECTORY ${bin_archive_dir}
	)
endif()