# Copyright (c) 2012, Merguez-IT
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Merguez-IT nor the names of its contributors may 
#       be used to endorse or promote products derived from this software 
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY MERGUEZ-IT AND CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL MERGUEZ-IT AND CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set(MAVEN_DEPENDENCY_PLUGIN_VERSION "2.5.1")

include(Utilities)
include(FindJava)

IF(${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows")
  find_program(MAVEN
    mvn.bat
    )
else()
  find_program(MAVEN
    mvn
    )
endif()
if(MAVEN)
  message(STATUS "Found maven: ${MAVEN}")
else()
  message(STATUS "Maven not found !")
endif()

find_program(XMLSTARTLET
  xml
  )
if(XMLSTARTLET)
  message(STATUS "Found XMLStartlet: ${XMLSTARTLET}")
else()
  message(WARNING "XMLStartlet (http://xmlstar.sourceforge.net) not found! I'll not parse POM")
endif()

function(find_version_in_pom POM_FILE RESULT)
  if(XMLSTARTLET)
    execute_process(
      COMMAND
      "${XMLSTARTLET}" "sel" "-N" "x=http://maven.apache.org/POM/4.0.0" "-t" "-m" "//x:project" "-v" "x:version" "${POM_FILE}"
      OUTPUT_VARIABLE CMD_RESULT
      )
    set(${RESULT} ${CMD_RESULT} PARENT_SCOPE)
  else(XMLSTARTLET)
    message(FATAL "XMLStartlet (http://xmlstar.sourceforge.net) is not installed!")
  endif(XMLSTARTLET)
endfunction(find_version_in_pom)

function(read_dependencies POM_FILE RESULT)
  if(XMLSTARTLET)
    execute_process(
      COMMAND
      "${XMLSTARTLET}" "sel" "-N" "x=http://maven.apache.org/POM/4.0.0" "-t" "-m" "//x:dependency" "-v" "x:groupId" "-o" ":" "-v" "x:artifactId" "-o" ":" "-v" "x:version" "-o" ":" "-v" "x:type" "-o" ";" "${POM_FILE}"
      OUTPUT_VARIABLE CMD_RESULT
      )
    set(${RESULT} ${CMD_RESULT} PARENT_SCOPE)
  else(XMLSTARTLET)
    message(FATAL "XMLStartlet (http://xmlstar.sourceforge.net) is not installed!")
  endif(XMLSTARTLET)
endfunction(read_dependencies)

# function(join VALUES GLUE OUTPUT)
#   string (REGEX REPLACE "([^\\]|^);" "\\1${GLUE}" _TMP_STR "${VALUES}")
#   string (REGEX REPLACE "[\\](.)" "\\1" _TMP_STR "${_TMP_STR}") #fixes escaping
#   set (${OUTPUT} "${_TMP_STR}" PARENT_SCOPE)
# endfunction()

# This function allow you to create a ZIP file
#
# Usage :
#
#   create_zip(name
#     ARCHIVE file.zip
#     FILES file ...
#     [WORKING_DIRECTORY path]
#     [DEPENDS depend ...]
#   )
function(create_zip ZIP_TARGET)
  unset(ZIP_ARCHIVE)
  unset(ZIP_FILES)
  unset(ZIP_DEPENDS)
  unset(ZIP_WORKING_DIRECTORY)

  if(Java_JAR_EXECUTABLE)
    parse_arguments(ZIP "ARCHIVE;FILES;DEPENDS;WORKING_DIRECTORY;" "" ${ARGN})

    if(NOT ZIP_FILES)
      message(FATAL_ERROR "No files specified for zip")
    endif()
    if(NOT ZIP_ARCHIVE)
      message(FATAL_ERROR "No archive name specified for zip")
    endif()

    if(NOT TARGET ${ZIP_TARGET})
      add_custom_target(${ZIP_TARGET}
        DEPENDS ${ZIP_DEPENDS}
        )
    elseif(ZIP_DEPENDS)
      add_dependencies(${ZIP_TARGET} ${ZIP_DEPENDS})
    endif()

    add_custom_command(
      TARGET ${ZIP_TARGET}
      DEPENDS ${ZIP_DEPENDS}
      WORKING_DIRECTORY "${ZIP_WORKING_DIRECTORY}"
      COMMAND "${Java_JAR_EXECUTABLE}" "cfM" "${ZIP_ARCHIVE}" ${ZIP_FILES}
      )
  else()
    message(WARNING "Please, install Java")
  endif()
endfunction()

# This function allow you to inflate a ZIP file
#
# Usage :
#
#   inflate_zip(name
#     ARCHIVE file.zip
#     [WORKING_DIRECTORY path]
#     [DEPENDS depend ...]
#   )
function(inflate_zip UNZIP_TARGET)
  unset(UNZIP_ARCHIVE)
  unset(UNZIP_DEPENDS)
  unset(UNZIP_WORKING_DIRECTORY)

  if(Java_JAR_EXECUTABLE)
    parse_arguments(UNZIP "ARCHIVE;DEPENDS;WORKING_DIRECTORY;" "" ${ARGN})

    if(NOT UNZIP_ARCHIVE)
      message(FATAL_ERROR "No archive name specified for unzip")
    endif()

    if(NOT TARGET ${UNZIP_TARGET})
      add_custom_target(${UNZIP_TARGET}
        DEPENDS ${UNZIP_DEPENDS}
        )
    elseif(UNZIP_DEPENDS)
      add_dependencies(${UNZIP_TARGET} ${UNZIP_DEPENDS})
    endif()

    add_custom_command(
      TARGET ${UNZIP_TARGET}
      DEPENDS ${UNZIP_DEPENDS}
      WORKING_DIRECTORY "${UNZIP_WORKING_DIRECTORY}"
      COMMAND "${Java_JAR_EXECUTABLE}" "xf" "${UNZIP_ARCHIVE}"
      )
  else()
    message(WARNING "Please, install Java")
  endif()
endfunction()

# This fiction allow you to deploy a file in a Maven repository
#
# usage : 
#
#  maven_deploy_file(target
#    FILE name
#    [POM file]
#    [GROUP_ID groupId]
#    [ARTIFACT_ID artifactId]
#    [VERSION version]
#    [PACKAGING zip|jar]
#    [REPOSITORY_ID repositoryId]
#    [URL repositoryUrl]
#    [DEPENDS depends ...]
#  )
#
# If repositoryId is not given, this function will use MAVEN_***_REPOSITORY_ID
# If repositoryUrl is not given, this function will use MAVEN_***_URL
function(maven_deploy_file MAVEN_TARGET)
  unset(MAVEN_FILE)
  unset(MAVEN_POM)
  unset(MAVEN_GROUP_ID)
  unset(MAVEN_ARTIFACT_ID)
  unset(MAVEN_VERSION)
  unset(MAVEN_PACKAGING)
  unset(MAVEN_REPOSITORY_ID)
  unset(MAVEN_URL)
  unset(MAVEN_DEPENDS)

  if(MAVEN)
    parse_arguments(MAVEN "FILE;POM;GROUP_ID;ARTIFACT_ID;VERSION;PACKAGING;REPOSITORY_ID;DEPENDS;URL;" "" ${ARGN})

    if(NOT MAVEN_FILE AND NOT MAVEN_POM)
      message(FATAL_ERROR "File and/or pom not specified for maven_deploy_file")
    endif()
    if(NOT MAVEN_GROUP_ID AND NOT MAVEN_POM)
      message(FATAL_ERROR "Group ID not specified for maven_deploy_file")
    endif()
    if(NOT MAVEN_ARTIFACT_ID AND NOT MAVEN_POM)
      message(FATAL_ERROR "Artifact ID not specified for maven_deploy_file")
    endif()
    if(NOT MAVEN_VERSION AND NOT MAVEN_POM)
      message(FATAL_ERROR "Version not specified for maven_deploy_file")
    endif()

    if(NOT MAVEN_VERSION)
      if(MAVEN_POM)
        if(XMLSTARTLET)
          get_filename_component(MAVEN_POM_PATH ${MAVEN_POM} PATH)
          if("${MAVEN_POM_PATH}" STREQUAL "") 
            find_version_in_pom(${CMAKE_CURRENT_BINARY_DIR}/${MAVEN_POM} MAVEN_VERSION)
          else()
            find_version_in_pom(${MAVEN_POM} MAVEN_VERSION)
          endif()
        else()
          message(FATAL_ERROR "Please install XMLStartlet (http://xmlstar.sourceforge.net) or specify VERSION in maven_deploy_file")
        endif()
      endif()
    endif()

    if(NOT MAVEN_REPOSITORY_ID)
      if(MAVEN_VERSION MATCHES "SNAPSHOT") 
        set(MAVEN_REPOSITORY_ID ${MAVEN_SNAPSHOT_REPOSITORY_ID})
      else()
        set(MAVEN_REPOSITORY_ID ${MAVEN_RELEASE_REPOSITORY_ID})
      endif()

      if(MAVEN_REPOSITORY_ID STREQUAL "")
        if(MAVEN_DEFAULT_REPOSITORY_ID)
          set(MAVEN_REPOSITORY_ID ${MAVEN_DEFAULT_REPOSITORY_ID})
        else()
          message(FATAL_ERROR "Repository ID not specified for maven_deploy_file")
        endif()
      endif()
    endif()

    if(NOT MAVEN_URL)
      if(MAVEN_VERSION MATCHES "SNAPSHOT")
        set(MAVEN_URL ${MAVEN_SNAPSHOT_URL})
      else()
        set(MAVEN_URL ${MAVEN_RELEASE_URL})
      endif()

      if("${MAVEN_URL}" STREQUAL "")
        if(MAVEN_DEFAULT_URL)
          set(MAVEN_URL ${MAVEN_DEFAULT_URL})
        else()
          message(FATAL_ERROR "Repository URL not specified for maven_deploy_file")
        endif()
      endif()
    endif()

    set(MAVEN_REMOTE_REPOSITORIES "")
    if(NOT "${MAVEN_REPOSITORY_ID}" STREQUAL "" AND NOT "${MAVEN_URL}" STREQUAL "") 
      set(MAVEN_REMOTE_REPOSITORIES "-DremoteRepositories=${MAVEN_REPOSITORY_ID}::::${MAVEN_URL}")
    endif()

    if(MAVEN_POM) 
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DgeneratePom=false")
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DpomFile=${MAVEN_POM}")
    endif()
    if(MAVEN_GROUP_ID AND NOT MAVEN_POM)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DgroupId=${MAVEN_GROUP_ID}") 
    endif()
    if(MAVEN_ARTIFACT_ID AND NOT MAVEN_POM)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DartifactId=${MAVEN_ARTIFACT_ID}")
    endif()
    if(MAVEN_VERSION AND NOT MAVEN_POM)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dversion=${MAVEN_VERSION}")
    endif()
    if(MAVEN_PACKAGING AND NOT MAVEN_POM)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dpackaging=${MAVEN_PACKAGING}") 
    endif()

    if(NOT TARGET ${MAVEN_TARGET})
      add_custom_target(${MAVEN_TARGET}
        DEPENDS ${MAVEN_DEPENDS}
        )
    elseif(MAVEN_DEPENDS)
      add_dependencies(${MAVEN_TARGET} ${MAVEN_DEPENDS})
    endif()

    if(NOT MAVEN_PACKAGING)
      set(MAVEN_PACKAGING jar)
    elseif(MAVEN_PACKAGING MATCHES "zip")
      get_filename_component(ARCHIVE_EXT ${MAVEN_FILE} EXT)
      if(NOT ARCHIVE_EXT MATCHES "zip")
        get_filename_component(ARCHIVE_PATH ${MAVEN_FILE} PATH)
        get_filename_component(ARCHIVE_NAME ${MAVEN_FILE} NAME_WE)
        get_filename_component(ZIP_CONTENT ${MAVEN_FILE} NAME)
        set(ZIP_FILENAME "${ARCHIVE_PATH}/${ARCHIVE_NAME}-${MAVEN_VERSION}.zip")
        set(MAVEN_FILE ${ZIP_FILENAME})
        create_zip(${MAVEN_TARGET} 
          ARCHIVE "${MAVEN_FILE}"
          FILES "${ZIP_CONTENT}"
          WORKING_DIRECTORY "${ARCHIVE_PATH}"
          )
      endif()
    endif()

    if(MAVEN_FILE) 
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dfile=${MAVEN_FILE}")
    elseif(MAVEN_POM)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dfile=${MAVEN_POM}")
    else()
      message(FATAL_ERROR "File and/or pom not specified for maven_deploy_file")
    endif()

    add_custom_command(
      TARGET ${MAVEN_TARGET}
      POST_BUILD
      COMMAND 
        "${MAVEN}" "deploy:deploy-file" 
        ${MAVEN_REMOTE_REPOSITORIES}
        ${MAVEN_EXTRA_ARGS}
      )
  else()
    message(WARNING "Please, install Maven")
  endif()
endfunction()

# This method allow you to get a dependency from a Maven repository
#
# usage :
#   maven_get_dependency(
#     GROUP_ID net.java.dev.jna
#     ARTIFACT_ID jna
#     VERSION 3.4.0
#     [PACKAGING jar]
#     [URL http://nexus.vidal.net:8081/nexus/content/groups/vidal-releases]
#     [DESTINATION /path/to/jna-3.4.0.jar]
#     [DEPENDS depends ...]
#     [TARGET target]
#     )
#
# If repositoryId is not given, this function will use MAVEN_***_REPOSITORY_ID
# If repositoryUrl is not given, this function will use MAVEN_***_URL
function(maven_get_dependency)
  unset(MAVEN_ARTIFACT)
  unset(MAVEN_TARGET)
  unset(MAVEN_GROUP_ID)
  unset(MAVEN_ARTIFACT_ID)
  unset(MAVEN_VERSION)
  unset(MAVEN_PACKAGING)
  unset(MAVEN_DESTINATION)
  unset(MAVEN_DESTINATION_PATH)
  unset(MAVEN_DEPENDS)
  unset(MAVEN_URL)
  unset(MAVEN_REPOSITORY_ID)

  if(MAVEN)
    parse_arguments(MAVEN "ARTIFACT;TARGET;GROUP_ID;ARTIFACT_ID;VERSION;PACKAGING;DESTINATION;DESTINATION_PATH;DEPENDS;URL;REPOSITORY_ID;OUTPUT;" "" ${ARGN})

    if(NOT MAVEN_GROUP_ID AND NOT MAVEN_ARTIFACT)
      message(FATAL_ERROR "Group ID not specified for maven_get_dependency")
    endif()
    if(NOT MAVEN_ARTIFACT_ID AND NOT MAVEN_ARTIFACT)
      message(FATAL_ERROR "Artifact ID not specified for maven_get_dependency")
    endif()
    if(NOT MAVEN_VERSION AND NOT MAVEN_ARTIFACT)
      message(FATAL_ERROR "Version not specified for maven_get_dependency")
    endif()
    if(NOT MAVEN_PACKAGING AND NOT MAVEN_ARTIFACT)
      set(MAVEN_PACKAGING "jar")
    endif()

    if(NOT MAVEN_ARTIFACT) 
      set(MAVEN_ARTIFACT "${MAVEN_GROUP_ID}:${MAVEN_ARTIFACT_ID}:${MAVEN_VERSION}:${MAVEN_PACKAGING}")
    else()
      string(REPLACE ":" ";" MAVEN_ARTIFACT_LIST ${MAVEN_ARTIFACT})
      list(GET MAVEN_ARTIFACT_LIST 2 MAVEN_VERSION)
    endif()

    if(NOT MAVEN_REPOSITORY_ID)
      if(MAVEN_VERSION MATCHES "SNAPSHOT") 
        set(MAVEN_REPOSITORY_ID ${MAVEN_SNAPSHOT_REPOSITORY_ID})
      else()
        set(MAVEN_REPOSITORY_ID ${MAVEN_RELEASE_REPOSITORY_ID})
      endif()

      if(MAVEN_REPOSITORY_ID STREQUAL "")
        if(MAVEN_DEFAULT_REPOSITORY_ID)
          set(MAVEN_REPOSITORY_ID ${MAVEN_DEFAULT_REPOSITORY_ID})
        else()
          message(FATAL_ERROR "Repository ID not specified for maven_deploy_file")
        endif()
      endif()
    endif()

    if(NOT MAVEN_URL)
      if(MAVEN_VERSION MATCHES "SNAPSHOT")
        set(MAVEN_URL ${MAVEN_SNAPSHOT_URL})
      else()
        set(MAVEN_URL ${MAVEN_RELEASE_URL})
      endif()

      if("${MAVEN_URL}" STREQUAL "")
        if(MAVEN_DEFAULT_URL)
          set(MAVEN_URL ${MAVEN_DEFAULT_URL})
        else()
          message(FATAL_ERROR "Repository URL not specified for maven_deploy_file")
        endif()
      endif()
    endif()

    set(MAVEN_REMOTE_REPOSITORIES "")
    if(NOT "${MAVEN_REPOSITORY_ID}" STREQUAL "" AND NOT "${MAVEN_URL}" STREQUAL "") 
      set(MAVEN_REMOTE_REPOSITORIES "-DremoteRepositories=${MAVEN_REPOSITORY_ID}::::${MAVEN_URL}")
    endif()

    if(MAVEN_DESTINATION_PATH AND NOT MAVEN_DESTINATION) 
      string(REGEX REPLACE ":" "." MAVEN_ARTIFACT_OUTPUT_FILE ${MAVEN_ARTIFACT})
      set(MAVEN_DESTINATION "${MAVEN_DESTINATION_PATH}/${MAVEN_ARTIFACT_OUTPUT_FILE}")
    endif()
    if(MAVEN_DESTINATION)
      set(${MAVEN_OUTPUT} ${MAVEN_DESTINATION} PARENT_SCOPE)
      set(MAVEN_DESTINATION "-Ddest=${MAVEN_DESTINATION}")
    endif()

    if(MAVEN_TARGET)
      if(NOT TARGET ${MAVEN_TARGET})
        add_custom_target(${MAVEN_TARGET}
          DEPENDS ${MAVEN_DEPENDS}
          )
      elseif(MAVEN_DEPENDS)
        add_dependencies(${MAVEN_TARGET} ${MAVEN_DEPENDS})
      endif()
    endif()
    
    if(CMAKE_VERBOSE_MAKEFILE)
      set(MAVEN_VERBOSE)
    else()
      set(MAVEN_VERBOSE OUTPUT_QUIET)
    endif()

    if(MAVEN_TARGET)
      add_custom_command(
        TARGET ${MAVEN_TARGET} 
        PRE_BUILD
        COMMAND
          "${MAVEN}" "org.apache.maven.plugins:maven-dependency-plugin:${MAVEN_DEPENDENCY_PLUGIN_VERSION}:get"
          "-Dartifact=${MAVEN_ARTIFACT}"
          ${MAVEN_REMOTE_REPOSITORIES}
          ${MAVEN_DESTINATION}
        )
    else()
      message(STATUS "Get maven dependency ${MAVEN_ARTIFACT} (${MAVEN_URL})")
      execute_process(
        COMMAND 
          "${MAVEN}" "org.apache.maven.plugins:maven-dependency-plugin:${MAVEN_DEPENDENCY_PLUGIN_VERSION}:get"
          "-Dartifact=${MAVEN_ARTIFACT}"
          ${MAVEN_REMOTE_REPOSITORIES}
          ${MAVEN_DESTINATION}
        ${MAVEN_VERBOSE}
        )
    endif()
  endif()

endfunction()

function(maven_install_file)
  unset(MAVEN_FILE)
  unset(MAVEN_POM)
  unset(MAVEN_GROUP_ID)
  unset(MAVEN_ARTIFACT_ID)
  unset(MAVEN_VERSION)
  unset(MAVEN_PACKAGING)
  unset(MAVEN_DEPENDS)

  if(MAVEN)
    parse_arguments(MAVEN "FILE;POM;GROUP_ID;ARTIFACT_ID;VERSION;PACKAGING;REPOSITORY_ID;DEPENDS;URL;" "" ${ARGN})

    if(NOT MAVEN_FILE AND NOT MAVEN_POM)
      message(FATAL_ERROR "File not specified for maven_install_file")
    endif()
    if(NOT MAVEN_GROUP_ID AND NOT MAVEN_POM)
      message(FATAL_ERROR "Group ID not specified for maven_install_file")
    endif()
    if(NOT MAVEN_ARTIFACT_ID AND NOT MAVEN_POM)
      message(FATAL_ERROR "Artifact ID not specified for maven_install_file")
    endif()
    if(NOT MAVEN_VERSION AND NOT MAVEN_POM)
      message(FATAL_ERROR "Version not specified for maven_install_file")
    endif()

    if(MAVEN_POM) 
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DgeneratePom=false")
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DpomFile=${MAVEN_POM}")
    endif()
    if(MAVEN_GROUP_ID)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DgroupId=${MAVEN_GROUP_ID}") 
    endif()
    if(MAVEN_ARTIFACT_ID)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-DartifactId=${MAVEN_ARTIFACT_ID}")
    endif()
    if(MAVEN_VERSION)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dversion=${MAVEN_VERSION}")
    endif()
    if(MAVEN_PACKAGING)
      set(MAVEN_EXTRA_ARGS ${MAVEN_EXTRA_ARGS} "-Dpackaging=${MAVEN_PACKAGING}") 
    endif()

    if(NOT TARGET ${MAVEN_TARGET})
      add_custom_target(${MAVEN_TARGET}
        DEPENDS ${MAVEN_DEPENDS}
        )
    elseif(MAVEN_DEPENDS)
      add_dependencies(${MAVEN_TARGET} ${MAVEN_DEPENDS})
    endif()

    if(NOT MAVEN_PACKAGING)
      set(MAVEN_PACKAGING jar)
    endif()

    add_custom_command(
      TARGET ${MAVEN_TARGET}
      POST_BUILD
      COMMAND 
        "${MAVEN}" "install:install-file" 
        "-Dfile=${MAVEN_FILE}" 
        ${MAVEN_EXTRA_ARGS}
      )
  else()
    message(WARNING "Please, install Maven")
  endif()
endfunction()
