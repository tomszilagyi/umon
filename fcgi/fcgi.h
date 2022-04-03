/* This file is part of uMon.
 * Copyright (c) 2022 Tom Szilagyi <tom.szilagyi@altmail.se>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/* Source: https://fastcgi-archives.github.io/FastCGI_Specification.html
 */

#pragma once

#include <stdint.h>

/*
 * Value for version component of FCGI_Header
 */
#define FCGI_VERSION_1           1

struct FCGI_Header
{
   uint8_t version = FCGI_VERSION_1;
   uint8_t type;
   uint8_t requestIdHi;
   uint8_t requestIdLo;
   uint8_t contentLengthHi;
   uint8_t contentLengthLo;
   uint8_t paddingLength;
   uint8_t reserved;
};

/*
 * Number of bytes in a FCGI_Header.  Future versions of the protocol
 * will not reduce this number.
 */
#define FCGI_HEADER_LEN  8

/*
 * Values for type component of FCGI_Header
 */
#define FCGI_BEGIN_REQUEST       1
#define FCGI_ABORT_REQUEST       2
#define FCGI_END_REQUEST         3
#define FCGI_PARAMS              4
#define FCGI_STDIN               5
#define FCGI_STDOUT              6
#define FCGI_STDERR              7
#define FCGI_DATA                8
#define FCGI_GET_VALUES          9
#define FCGI_GET_VALUES_RESULT  10
#define FCGI_UNKNOWN_TYPE       11
#define FCGI_MAXTYPE (FCGI_UNKNOWN_TYPE)

/*
 * Value for requestId component of FCGI_Header
 */
#define FCGI_NULL_REQUEST_ID     0

struct FCGI_BeginRequestBody
{
   unsigned char roleHi;
   unsigned char roleLo;
   unsigned char flags;
   unsigned char reserved [5];
};

struct FCGI_BeginRequest
{
   FCGI_Header header;
   FCGI_BeginRequestBody body;
};

/*
 * Mask for flags component of FCGI_BeginRequestBody
 */
#define FCGI_KEEP_CONN  1

/*
 * Values for role component of FCGI_BeginRequestBody
 */
#define FCGI_RESPONDER  1
#define FCGI_AUTHORIZER 2
#define FCGI_FILTER     3

/*
 * Values for protocolStatus component of FCGI_EndRequestBody
 */
#define FCGI_REQUEST_COMPLETE 0
#define FCGI_CANT_MPX_CONN    1
#define FCGI_OVERLOADED       2
#define FCGI_UNKNOWN_ROLE     3

struct FCGI_EndRequestBody
{
   unsigned char appStatusB3 = 0;
   unsigned char appStatusB2 = 0;
   unsigned char appStatusB1 = 0;
   unsigned char appStatusB0 = 0;
   unsigned char protocolStatus = FCGI_REQUEST_COMPLETE;
   unsigned char reserved [3] = {0, 0, 0};
};

struct FCGI_EndRequest
{
   FCGI_Header header;
   FCGI_EndRequestBody body;
};

/*
 * Variable names for FCGI_GET_VALUES / FCGI_GET_VALUES_RESULT records
 */
#define FCGI_MAX_CONNS  "FCGI_MAX_CONNS"
#define FCGI_MAX_REQS   "FCGI_MAX_REQS"
#define FCGI_MPXS_CONNS "FCGI_MPXS_CONNS"

struct FCGI_UnknownTypeBody
{
   unsigned char type;
   unsigned char reserved [7];
};

struct FCGI_UnknownType
{
   FCGI_Header header;
   FCGI_UnknownTypeBody body;
};
