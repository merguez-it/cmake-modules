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

include(Utilities)

function(QT4_GENERATE_QRC QRC_FILENAME)
  unset(QRC_PATH)
  unset(QRC_PREFIX)
  unset(QRC_BASE)
  unset(QRC_RECURSIVE)
  parse_arguments(QRC "PATH;PREFIX;RECURSIVE;BASE;" "" ${ARGN})

  if(NOT QRC_PATH)
    message(FATAL_ERROR "No path specified for resources")
  endif()
  if(NOT QRC_PREFIX)
    set(QRC_PREFIX "/")
  endif()
  if(QRC_BASE AND NOT QRC_BASE MATCHES ".*[/|\\]{1}$")
      set(QRC_BASE "${QRC_BASE}/")
  endif()
  if(QRC_RECURSIVE) 
    set(QRC_RECURSIVE "GLOB_RECURSE")
  else()
    set(QRC_RECURSIVE "GLOB")
  endif()

  file(${QRC_RECURSIVE} QRC_FILES RELATIVE ${QRC_PATH} ${QRC_PATH}/*.*)

  file(WRITE ${QRC_FILENAME} "<!DOCTYPE RCC>\n<RCC version=\"1.0\">\n<qresource prefix=\"${QRC_PREFIX}\">\n")
  foreach(QRC_CURRENT_FILE ${QRC_FILES})
    file(TO_CMAKE_PATH "${QRC_BASE}${QRC_CURRENT_FILE}" QRC_FINAL_FILE)
    file(APPEND ${QRC_FILENAME} "<file>${QRC_FINAL_FILE}</file>\n")
  endforeach()
  file(APPEND ${QRC_FILENAME} "</qresource>\n</RCC>\n")
endfunction()

function(QT4_ADD_RESOURCES_FROM_DIR SOURCES)
  unset(QARFD_NAME)
  unset(QARFD_PATH)
  unset(QARFD_RECURSIVE)
  unset(QARFD_PREFIX)
  parse_arguments(QARFD "PATH;NAME;RECURSIVE;PREFIX;" "" ${ARGN})

  if(NOT QARFD_NAME)
    message(FATAL_ERROR "You must give a name for your resources")
  endif()
  if(NOT QARFD_PATH)
    message(FATAL_ERROR "No path given for resources")
  endif()
  if(QARFD_RECURSIVE) 
    set(QARFD_RECURSIVE ON)
  else()
    set(QARFD_RECURSIVE OFF)
  endif()
  if(NOT QARFD_PREFIX)
    set(QARFD_PREFIX "/")
  endif()

  message(STATUS "Copy resources")
  file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/${QARFD_PATH} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})

  string(REPLACE "/" ";" QARFD_PATH_LIST ${QARFD_PATH})
  list(GET QARFD_PATH_LIST -1 QARFD_PATH_LIST_LAST)

  message(STATUS "Generate ${CMAKE_CURRENT_BINARY_DIR}/${QARFD_NAME}.qrc")
  set(QARFD_QRC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${QARFD_NAME}.qrc)
  QT4_GENERATE_QRC(${QARFD_QRC_FILE}
    PATH ${CMAKE_CURRENT_BINARY_DIR}/${QARFD_PATH_LIST_LAST}
    BASE ${QARFD_PATH_LIST_LAST}
    RECURSIVE ${QARFD_RECURSIVE}
    PREFIX ${QARFD_PREFIX}
    )
  QT4_ADD_RESOURCES(${SOURCES} ${QARFD_QRC_FILE})
  set(${SOURCES} ${${SOURCES}} PARENT_SCOPE)
endfunction()
