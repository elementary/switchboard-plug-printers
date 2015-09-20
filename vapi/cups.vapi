/* CUPS Vala Bindings
 * Copyright 2009-2010 Evan Nemerson <evan@coeus-group.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
 * BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
 * ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/* Status:
 *   cups.h, array.h are mostly done. Nothing else is, but
 *   patches are welcome. I'm not sure if I'll ever get around to
 *   finishing them unless there is a demand (what I need is done), so
 *   if you're actually using these let me know.
 */

[CCode (cheader_filename = "cups/cups.h")]
namespace CUPS {
	public const double VERSION;
	public const int VERSION_MAJOR;
	public const int VERSION_MINOR;
	public const int VERSION_PATCH;
	public const int DATE_ANY;

	[CCode (cname = "cups_ptype_t")]
	public enum PriterType {
		LOCAL,
		CLASS,
		REMOTE,
		BW,
		COLOR,
		DUPLEX,
		STAPLE,
		COPIES,
		COLLATE,
		PUNCH,
		COVER,
		BIND,
		SORT,
		SMALL,
		MEDIUM,
		LARGE,
		VARIABLE,
		IMPLICIT, /* Deprecated */
		DEFAULT,
		FAX,
		REJECTING,
		DELETE,
		NOT_SHARED,
		AUTHENTICATED,
		COMMANDS,
		DISCOVERED, /* Deprecated */
		OPTIONS
	}

	[CCode (cname = "cupsCopyDestInfo")]
	public CUPS.DestinationInformation copy_destination_information (CUPS.HTTP.HTTP http, CUPS.Destination dest);
	[CCode (cname = "cupsCheckDestSupported")]
	public int check_destination_supported (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option, string value);

	[Compact, CCode (cname = "cups_dinfo_t", free_function = "cupsFreeDestInfo")]
	public class DestinationInformation {
		
	}

	[CCode (cname = "cupsFindDestDefault")]
	public unowned CUPS.IPP.Attribute find_destination_default (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option);
	[CCode (cname = "cupsFindDestReady")]
	public unowned CUPS.IPP.Attribute find_destination_ready (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option);
	[CCode (cname = "cupsFindDestSupported")]
	public unowned CUPS.IPP.Attribute find_destination_supported (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option);
	[CCode (cname = "cupsLocalizeDestOption")]
	public unowned string localize_destination_option (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option);
	[CCode (cname = "cupsLocalizeDestValue")]
	public unowned string localize_destination_value (CUPS.HTTP.HTTP http, CUPS.Destination dest, CUPS.DestinationInformation info, string option, string value);

	[CCode (cname = "cupsGetOption")]
	public unowned string get_option (string name, [CCode (array_length_pos = 1.1)] Option[] options);
	[CCode (cname = "cupsAddOption")]
	public int add_option (string name, string value, int num_options, [CCode (array_length = false)] ref Option[] options);
	[CCode (cname = "cupsLastError")]
	public CUPS.IPP.Status last_error ();

	[CCode (cname = "cups_option_t", destroy_function = "")]
	public struct Option {
		public string name;
		public string value;
	}

	[CCode (cname = "cups_dest_t")]
	public struct Destination {
		public string name;
		public string instance;
		[CCode (cname = "is_default")]
		public int _is_default;
		public bool is_default {
			get {
				return _is_default == 1;
			}
			set {
				_is_default = value ? 1 : 0;
			}
		}
		public int num_options;
		[CCode (array_length_cname = "num_options")]
		public Option[] options;
		[CCode (cname = "cupsFreeDests")]
		public static void free (int num_dests, Destination[] dests);
		[CCode (cname = "cupsGetDest")]
		public static unowned Destination? get_dest (string name, string? instance, [CCode (array_length_pos = 0.9)] Destination[] dests);
		[CCode (cname = "cupsGetDests")]
		public static int get_dests ([CCode (array_length = false)] out unowned Destination[] dests);

		public unowned CUPS.Job[] get_jobs (bool my_jobs, CUPS.WhichJobs whichjobs) {
			return CUPS.get_jobs (this.name, my_jobs, whichjobs);
		}

		public int print_file (string filename, string title, Option[]? options) {
			return CUPS.print_file (this.name, filename, title, options);
		}
	}

	[CCode (cname = "int", cprefix = "CUPS_WHICHJOBS_", has_type_id = false)]
	public enum WhichJobs {
		ALL,
		ACTIVE,
		COMPLETED
	}

	[CCode (cname = "cupsGetJobs")]
	private int _get_jobs ([CCode (array_length = false)] out unowned CUPS.Job[] jobs, string name, int my_jobs, CUPS.WhichJobs whichjobs);
	public unowned CUPS.Job[] get_jobs (string name, bool my_jobs, CUPS.WhichJobs whichjobs) {
		unowned CUPS.Job[] temp;
		var len = _get_jobs (out temp, name, my_jobs ? 1 : 0, whichjobs);
		temp.length = len;
		return temp;
	}

	[CCode (cname = "cups_job_t")]
	public struct Job {
		public int id;
		public string dest;
		public string title;
		public string user;
		public string format;
		public IPP.JobState state;
		public int size;
		public int priority;
		public time_t completed_time;
		public time_t creation_time;
		public time_t processing_time;
	}

	[CCode (cname = "cups_size_t")]
	public struct Size {
		public char media[128];
		public int width;
		public int length;
		public int bottom;
		public int left;
		public int right;
		public int top;
	}

	[CCode (cname = "cupsPrintFile")]
	public int print_file (string printer, string filename, string title, [CCode (array_length_pos = 3.9)] Option[]? options);
	[CCode (cname = "cupsGetDests")]
	private int _get_destinations ([CCode (array_length = false)] out unowned CUPS.Destination[] destinations);
	public unowned CUPS.Destination[] get_destinations () {
		unowned CUPS.Destination[] temp;
		var len = _get_destinations (out temp);
		temp.length = len;
		return temp;
	}
	[CCode (cname = "cupsUser")]
	public unowned string get_user ();
	[CCode (cname = "cupsServer")]
	public unowned string get_server ();

	/* Better alternatives exist in both GLib and Gee. */
	[Compact, CCode (cname = "cups_array_t", copy_function = "cupsArrayDup", free_function = "cupsArrayDelete", cheader_filename = "cups/array.h")]
	public class Array <T> {
		public int add (T e);
		public void clear ();
		public int count ();
		public unowned T current ();
		public unowned T find (T e);
		public unowned T first ();
		public int get_index ();
		public int get_insert ();
		public unowned T index (int n);
		public int insert (T e);
		public unowned T last ();
		public Array (ArrayFunc f, T d);
		public Array.with_hash (ArrayFunc f, T d, ArrayHashFunc h, int hsize);
		public unowned T next ();
		public unowned T prev ();
		public int remove (T e);
		public unowned T restore ();
		public int save ();
	}

	[CCode (cname = "cups_array_func_t", cheader_filename = "cups/array.h")]
	public delegate int ArrayFunc (void * first, void * second);
	[CCode (cname = "cups_ahash_func_t", cheader_filename = "cups/array.h")]
	public delegate int ArrayHashFunc (void * element);

	[CCode (cheader_filename = "cups/ipp.h", lower_case_cprefix = "ipp_")]
	namespace IPP {
		[CCode (cname = "IPP_PORT")]
		public const int PORT;
		[CCode (cname = "IPP_MAX_LENGTH")]
		public const int MAX_LENGTH;
		[CCode (cname = "IPP_MAX_NAME")]
		public const int MAX_NAME;
		[CCode (cname = "IPP_MAX_VALUES")]
		public const int MAX_VALUES;

		[CCode (cname = "ipp_tag_t", cprefix = "IPP_TAG_")]
		public enum Tag {
			ZERO,
			OPERATION,
			JOB,
			END,
			PRINTER,
			UNSUPPORTED_GROUP,
			SUBSCRIPTION,
			EVENT_NOTIFICATION,
			UNSUPPORTED_VALUE,
			DEFAULT,
			UNKNOWN,
			NOVALUE,
			NOTSETTABLE,
			DELETEATTR,
			ADMINDEFINE,
			INTEGER,
			BOOLEAN,
			ENUM,
			STRING,
			DATE,
			RESOLUTION,
			RANGE,
			BEGIN_COLLECTION,
			TEXTLANG,
			NAMELANG,
			END_COLLECTION,
			TEXT,
			NAME,
			KEYWORD,
			URI,
			URISCHEME,
			CHARSET,
			LANGUAGE,
			MIMETYPE,
			MEMBERNAME,
			MASK,
			COPY;
			[CCode(cname = "ippTagString")]
			public unowned string to_string ();
			[CCode(cname = "ippTagValue")]
			public static CUPS.IPP.Tag from_string (string name);
		}

		[CCode (cname = "ipp_res_t", cprefix = "IPP_RES_")]
		public enum Resolution {
			PER_INCH,
			PER_CM
		}

		[CCode (cname = "ipp_finish_t", cprefix = "IPP_FINISHINGS_")]
		public enum Finishing {
			NONE,
			STAPLE,
			PUNCH,
			COVER,
			BIND,
			SADDLE_STITCH,
			EDGE_STITCH,
			FOLD,
			TRIM,
			BALE,
			BOOKLET_MAKER,
			JOB_OFFSET,
			STAPLE_TOP_LEFT,
			STAPLE_BOTTOM_LEFT,
			STAPLE_TOP_RIGHT,
			STAPLE_BOTTOM_RIGHT,
			EDGE_STITCH_LEFT,
			EDGE_STITCH_TOP,
			EDGE_STITCH_RIGHT,
			EDGE_STITCH_BOTTOM,
			STAPLE_DUAL_LEFT,
			STAPLE_DUAL_TOP,
			STAPLE_DUAL_RIGHT,
			STAPLE_DUAL_BOTTOM,
			BIND_LEFT,
			BIND_TOP,
			BIND_RIGHT,
			BIND_BOTTOM
		}

		[CCode (cname = "ipp_orient_t", cprefix = "IPP_")]
		public enum Orientation {
			PORTRAIT,
			LANDSCAPE,
			REVERSE_LANDSCAPE,
			REVERSE_PORTRAIT
		}

		[CCode (cname = "ipp_quality_t", cprefix = "IPP_QUALITY_")]
		public enum Quality {
			DRAFT,
			NORMAL,
			HIGH
		}

		[CCode (cname = "ipp_jstate_t", cprefix = "IPP_JOB_", has_type_id = false)]
		public enum JobState {
			PENDING,
			HELD,
			PROCESSING,
			STOPPED,
			CANCELED,
			ABORTED,
			COMPLETED
		}

		[CCode (cname = "ipp_pstate_t", cprefix = "IPP_PRINTER_")]
		public enum PrinterState {
			IDLE,
			PROCESSING,
			STOPPED
		}

		[CCode (cname = "ipp_state_t", cprefix = "IPP_")]
		public enum State {
			ERROR,
			IDLE,
			HEADER,
			ATTRIBUTE,
			DATA
		}

		[CCode (cname = "ipp_op_t", cprefix = "IPP_")]
		public enum Operation {
			PRINT_JOB,
			PRINT_URI,
			VALIDATE_JOB,
			CREATE_JOB,
			SEND_DOCUMENT,
			SEND_URI,
			CANCEL_JOB,
			GET_JOB_ATTRIBUTES,
			GET_JOBS,
			GET_PRINTER_ATTRIBUTES,
			HOLD_JOB,
			RELEASE_JOB,
			RESTART_JOB,
			PAUSE_PRINTER,
			RESUME_PRINTER,
			PURGE_JOBS,
			SET_PRINTER_ATTRIBUTES,
			SET_JOB_ATTRIBUTES,
			GET_PRINTER_SUPPORTED_VALUES,
			CREATE_PRINTER_SUBSCRIPTION,
			CREATE_JOB_SUBSCRIPTION,
			GET_SUBSCRIPTION_ATTRIBUTES,
			GET_SUBSCRIPTIONS,
			RENEW_SUBSCRIPTION,
			CANCEL_SUBSCRIPTION,
			GET_NOTIFICATIONS,
			SEND_NOTIFICATIONS,
			GET_PRINT_SUPPORT_FILES,
			ENABLE_PRINTER,
			DISABLE_PRINTER,
			PAUSE_PRINTER_AFTER_CURRENT_JOB,
			HOLD_NEW_JOBS,
			RELEASE_HELD_NEW_JOBS,
			DEACTIVATE_PRINTER,
			ACTIVATE_PRINTER,
			RESTART_PRINTER,
			SHUTDOWN_PRINTER,
			STARTUP_PRINTER,
			REPROCESS_JOB,
			CANCEL_CURRENT_JOB,
			SUSPEND_CURRENT_JOB,
			RESUME_JOB,
			PROMOTE_JOB,
			SCHEDULE_JOB_AFTER,
			PRIVATE,
			CUPS_GET_DEFAULT,
			CUPS_GET_PRINTERS,
			CUPS_ADD_MODIFY_PRINTER,
			CUPS_DELETE_PRINTER,
			CUPS_GET_CLASSES,
			CUPS_ADD_MODIFY_CLASS,
			CUPS_DELETE_CLASS,
			CUPS_ACCEPT_JOBS,
			CUPS_REJECT_JOBS,
			CUPS_SET_DEFAULT,
			CUPS_GET_DEVICES,
			CUPS_GET_PPDS,
			CUPS_MOVE_JOB,
			CUPS_AUTHENTICATE_JOB,
			CUPS_GET_PPD;
			[CCode(cname = "ippOpString")]
			public unowned string to_string ();
			[CCode(cname = "ippOpValue")]
			public static CUPS.IPP.Operation from_string (string name);
		}

		[CCode (cname = "ipp_status_t", cprefix = "IPP_")]
		public enum Status {
			OK,
			OK_SUBST,
			OK_CONFLICT,
			OK_IGNORED_SUBSCRIPTIONS,
			OK_IGNORED_NOTIFICATIONS,
			OK_TOO_MANY_EVENTS,
			OK_BUT_CANCEL_SUBSCRIPTION,
			OK_EVENTS_COMPLETE,
			REDIRECTION_OTHER_SITE,
			CUPS_SEE_OTHER,
			BAD_REQUEST,
			FORBIDDEN,
			NOT_AUTHENTICATED,
			NOT_AUTHORIZED,
			NOT_POSSIBLE,
			TIMEOUT,
			NOT_FOUND,
			GONE,
			REQUEST_ENTITY,
			REQUEST_VALUE,
			DOCUMENT_FORMAT,
			ATTRIBUTES,
			URI_SCHEME,
			CHARSET,
			CONFLICT,
			COMPRESSION_NOT_SUPPORTED,
			COMPRESSION_ERROR,
			DOCUMENT_FORMAT_ERROR,
			DOCUMENT_ACCESS_ERROR,
			ATTRIBUTES_NOT_SETTABLE,
			IGNORED_ALL_SUBSCRIPTIONS,
			TOO_MANY_SUBSCRIPTIONS,
			IGNORED_ALL_NOTIFICATIONS,
			PRINT_SUPPORT_FILE_NOT_FOUND,
			INTERNAL_ERROR,
			OPERATION_NOT_SUPPORTED,
			SERVICE_UNAVAILABLE,
			VERSION_NOT_SUPPORTED,
			DEVICE_ERROR,
			TEMPORARY_ERROR,
			NOT_ACCEPTING,
			PRINTER_BUSY,
			ERROR_JOB_CANCELED,
			MULTIPLE_JOBS_NOT_SUPPORTED,
			PRINTER_IS_DEACTIVATED;
			[CCode(cname = "ippErrorString")]
			public unowned string to_string ();
			[CCode(cname = "ippErrorValue")]
			public static CUPS.IPP.Status from_string (string name);
		}

		[CCode (cname = "struct { ipp_uchar_t version[2]; int op_status; int request_id; }")]
		public struct RequestAny {
			public uchar version[2];
			public int op_status;
			public int request_id;
		}

		[CCode (cname = "struct { ipp_uchar_t version[2]; ipp_op_t operation_id; int request_id; }")]
		public struct RequestOperation {
			public uchar version[2];
			public Operation operation_id;
			public int request_id;
		}

		[CCode (cname = "struct { ipp_uchar_t version[2]; ipp_status_t status_code; int request_id; }")]
		public struct RequestStatus {
			public uchar version[2];
			public Status status_code;
			public int request_id;
		}

		[CCode (cname = "struct { ipp_uchar_t version[2]; ipp_status_t status_code; int request_id; }")]
		public struct RequestEvent {
			public uchar version[2];
			public Status status_code;
			public int request_id;
		}

		[CCode (cname = "ipp_request_t")]
		public class Request {
			public RequestAny any;
			public RequestOperation op;
			public RequestStatus status;
			public RequestEvent @event;
		}

		[CCode (cname = "ipp_attribute_t")]
		public class Attribute {
			public Attribute? next;
			public Tag group_tag;
			public Tag value_tag;
			public string name;
			public int num_values;
			[CCode (array_length_cname = "num_values")]
			public unowned CUPS.IPP.Value[] values;
			[CCode(cname = "ippGetCount")]
			public int get_count ();
			[CCode(cname = "ippGetDate")]
			public uchar[] get_date (int element = 0);
			[CCode(cname = "ippGetBoolean")]
			private int _get_bool (int element);
			public bool get_bool (int element = 0) {
				return _get_bool (element) == 1;
			}
			[CCode(cname = "ippGetCollection")]
			public unowned CUPS.IPP.IPP get_collection (int element = 0);
			[CCode(cname = "ippGetGroupTag")]
			public CUPS.IPP.Tag get_group_tag (int element = 0);
			[CCode(cname = "ippGetInteger")]
			public int get_integer (int element = 0);
			[CCode(cname = "ippGetName")]
			public unowned string get_name ();
			[CCode(cname = "ippGetOctetString")]
			public void* get_octet_string (int element, out int datalen);
			[CCode(cname = "ippGetOperation")]
			public CUPS.IPP.Operation get_operation ();
			[CCode(cname = "ippGetRange")]
			public int get_range (int element, out int upper_value);
			[CCode(cname = "ippGetResolution")]
			public int get_resolution (int element, out int y_res, out CUPS.IPP.Resolution units);
			[CCode(cname = "ippGetString")]
			public unowned string get_string (int element = 0, string? language = null);
			[CCode(cname = "ippGetValueTag")]
			public CUPS.IPP.Tag get_value_tag ();
		}

		[CCode (cname = "ipp_value_t", cheader_filename = "cups/ipp.h")]
		public struct Value {
			public int integer;
			public char boolean;
			public uchar date[11];
			[CCode(cname = "resolution.xres")]
			public int resolution_x;
			[CCode(cname = "resolution.yres")]
			public int resolution_y;
			[CCode(cname = "resolution.units")]
			public CUPS.IPP.Resolution resolution_units;

			[CCode(cname = "range.lower")]
			public int range_lower;
			[CCode(cname = "range.upper")]
			public int range_upper;

			[CCode(cname = "string.language")]
			public string string_language;
			[CCode(cname = "string.text")]
			public string string_text;

			[CCode(cname = "unknown.length")]
			public int unknown_length;
			[CCode(cname = "unknown.data")]
			public void* unknown_data;

			public CUPS.IPP.IPP collection;
		}

		[CCode (cname = "ippPort")]
		public static int port ();
		[CCode (cname = "ippSetPort")]
		public static void set_port (int port);

		[Compact, CCode (cname = "ipp_t", free_function = "ippDelete")]
		public class IPP {
			public State state;

			// Doesn't actually return a modified pointer, but rather a
			// whole new object, and frees the old one. Still, this is the
			// only way I can think of to make this work in vala, since
			// there is no ippCopy()
			[ReturnsModifiedPointer, CCode (cname = "cupsDoRequest", instance_pos = 1.1)]
			public void do_request (HTTP.HTTP http, string resource = "/");

			[CCode (cname = "ippNew")]
			public IPP ();
			[CCode (cname = "ippNewRequest")]
			public IPP.request (Operation op);
			[CCode (cname = "ippNewResponse")]
			public IPP.response (CUPS.IPP.IPP request);
			[CCode (cname = "ippFirstAttribute")]
			public unowned Attribute first_attribute ();
			[CCode (cname = "ippNextAttribute")]
			public unowned Attribute next_attribute ();
			[CCode (cname = "ippAddBoolean")]
			private unowned Attribute _add_boolean (Tag group, string name, char value);
			public unowned Attribute add_boolean (Tag group, string name, bool value) {
				return _add_boolean (group, name, value ? 1 : 0);
			}
			[CCode (cname = "ippAddBooleans")]
			private unowned Attribute _add_booleans (Tag group, string name, [CCode (array_length_pos = 0.9)] char[] values);
			public unowned Attribute add_booleans (Tag group, string name, bool[] values) {
				char[] char_values;
				foreach (var val in values) {
					char_values += val ? 1 : 0;
				}

				return _add_booleans (group, name, char_values);
			}
			[CCode (cname = "ippAddString")]
			public unowned Attribute add_string (Tag group, Tag type, string name, string? charset, string value);
			[CCode (cname = "ippAddStrings")]
			public unowned Attribute add_strings (Tag group, Tag type, string name, string? language, [CCode (array_length_pos = 3.9)] string[] values);
			[CCode(cname = "ippGetRequestId")]
			public int get_request_id ();
			[CCode(cname = "ippGetState")]
			public CUPS.IPP.State get_state ();
			[CCode(cname = "ippSetState")]
			public int set_state (CUPS.IPP.State state);
			[CCode(cname = "ippGetStatusCode")]
			public CUPS.IPP.Status get_status_code ();
			[CCode(cname = "ippSetStatusCode")]
			public int set_status_code (CUPS.IPP.Status status);
			[CCode(cname = "ippGetVersion")]
			public int get_version (out int minor);
			[CCode(cname = "ippSetVersion")]
			private int _set_version (int major, int minor);
			public bool set_version (int major, int minor) {
				return _set_version (major, minor) == 1;
			}
			[CCode(cname = "ippLength")]
			public size_t length ();
			[CCode(cname = "ippFindAttribute")]
			public unowned CUPS.IPP.Attribute find_attribute (string name, CUPS.IPP.Tag type);
			[CCode(cname = "ippFindNextAttribute")]
			public unowned CUPS.IPP.Attribute find_next_attribute (string name, CUPS.IPP.Tag type);
		}
	}

	namespace HTTP {
		[CCode (cname = "HTTP_MAX_URI")]
		public const int MAX_URI;
		[CCode (cname = "HTTP_MAX_HOST")]
		public const int MAX_HOST;
		[CCode (cname = "HTTP_MAX_BUFFER")]
		public const int MAX_BUFFER;
		[CCode (cname = "HTTP_MAX_VALUE")]
		public const int MAX_VALUE;

		[CCode (cname = "http_uri_status_t", cprefix = "HTTP_URI_")]
		public enum URIStatus {
			BAD_ARGUMENTS,
			BAD_HOSTNAME,
			BAD_PORT,
			BAD_RESOURCE,
			BAD_SCHEME,
			BAD_URI,
			BAD_USERNAME,
			MISSING_RESOURCE,
			MISSING_SCHEME,
			OK,
			OVERFLOW,
			UNKNOWN_SCHEME,
		}

		[CCode (cname = "http_uri_coding_t", cprefix = "HTTP_URI_CODING_")]
		public enum URICoding {
			ALL,
			HOSTNAME,
			MOST,
			NONE,
			QUERY,
			RESOURCE,
			USERNAME
		}

		[CCode (cname = "httpAssembleURIf", sentinel = ""), PrintfFormat]
		public static URIStatus assemble_uri_f (URICoding encoding, char[] uri, string scheme, string? username, string host, int port, ...);

		[CCode (cname = "CUPS_HTTP_DEFAULT")]
		public static HTTP DEFAULT;

		[Compact, CCode (cname = "http_t", free_function = "httpClose")]
		public class HTTP {
			[CCode (cname = "httpConnect")]
			public HTTP (string host, int port);

			public IPP.IPP do_request (IPP.IPP request, string resource);
			public IPP.IPP do_file_request (IPP.IPP request, string resource, string filename);
		}
	}

	namespace Lang {

		[CCode (cname = "cups_encoding_t", cprefix = "CUPS_")]
		public enum Encoding {
			AUTO_ENCODING = -1,		/* Auto-detect the encoding @private@ */
			US_ASCII,				/* US ASCII */
			ISO8859_1,				/* ISO-8859-1 */
			ISO8859_2,				/* ISO-8859-2 */
			ISO8859_3,				/* ISO-8859-3 */
			ISO8859_4,				/* ISO-8859-4 */
			ISO8859_5,				/* ISO-8859-5 */
			ISO8859_6,				/* ISO-8859-6 */
			ISO8859_7,				/* ISO-8859-7 */
			ISO8859_8,				/* ISO-8859-8 */
			ISO8859_9,				/* ISO-8859-9 */
			ISO8859_10,				/* ISO-8859-10 */
			UTF8,					/* UTF-8 */
			ISO8859_13,				/* ISO-8859-13 */
			ISO8859_14,				/* ISO-8859-14 */
			ISO8859_15,				/* ISO-8859-15 */
			WINDOWS_874,			/* CP-874 */
			WINDOWS_1250,			/* CP-1250 */
			WINDOWS_1251,			/* CP-1251 */
			WINDOWS_1252,			/* CP-1252 */
			WINDOWS_1253,			/* CP-1253 */
			WINDOWS_1254,			/* CP-1254 */
			WINDOWS_1255,			/* CP-1255 */
			WINDOWS_1256,			/* CP-1256 */
			WINDOWS_1257,			/* CP-1257 */
			WINDOWS_1258,			/* CP-1258 */
			KOI8_R,					/* KOI-8-R */
			KOI8_U,					/* KOI-8-U */
			ISO8859_11,				/* ISO-8859-11 */
			ISO8859_16,				/* ISO-8859-16 */
			MAC_ROMAN,				/* MacRoman */

			WINDOWS_932,			/* Japanese JIS X0208-1990 */
			WINDOWS_936,			/* Simplified Chinese GB 2312-80 */
			WINDOWS_949,			/* Korean KS C5601-1992 */
			WINDOWS_950,			/* Traditional Chinese Big Five */
			WINDOWS_1361,			/* Korean Johab */

			EUC_CN,					/* EUC Simplified Chinese */
			EUC_JP,					/* EUC Japanese */
			EUC_KR,					/* EUC Korean */
			EUC_TW,					/* EUC Traditional Chinese */
			JIS_X0213;				/* JIS X0213 aka Shift JIS */
			[CCode(cname = "_cupsEncodingName")]
			public unowned string to_string ();
		}


		[Compact, CCode (cname = "cups_lang_t", free_function = "cupsLangFree")]
		public class Lang {
			CUPS.Lang.Lang next;
			int used;
			Encoding encoding;
			char language[16];

			[CCode (cname = "cupsLangGet")]
			public Lang (string language);
			[CCode (cname = "cupsLangDefault")]
			public Lang.default ();

			[CCode (cname = "cupsLangEncoding")]
			public unowned string get_encoding ();
			[CCode (cname = "_cupsLangString")]
			public unowned string get_string (string message);

			[CCode (cname = "cupsLangFlush")]
			public static void flush ();
		}
	}

	namespace Attributes {
		[CCode (cname = "CUPS_NUMBER_UP_SUPPORTED")]
		public const string NUMBER_UP_SUPPORTED;
		[CCode (cname = "\"number-up-default\"")]
		public const string NUMBER_UP_DEFAULT;

		[CCode (cname = "CUPS_SIDES_SUPPORTED")]
		public const string SIDES_SUPPORTED;
		[CCode (cname = "\"sides-default\"")]
		public const string SIDES_DEFAULT;

		[CCode (cname = "CUPS_ORIENTATION_SUPPORTED")]
		public const string ORIENTATION_SUPPORTED;
		[CCode (cname = "\"orientation-requested-default\"")]
		public const string ORIENTATION_DEFAULT;

		[CCode (cname = "CUPS_MEDIA_SUPPORTED")]
		public const string MEDIA_SUPPORTED;
		[CCode (cname = "\"media-supported-default\"")]
		public const string MEDIA_DEFAULT;

		[CCode (cname = "\"media-size-supported\"")]
		public const string MEDIA_SIZE_SUPPORTED;

		namespace Sided {
			[CCode (cname = "CUPS_SIDES_ONE_SIDED")]
			public const string ONE;
			[CCode (cname = "CUPS_SIDES_TWO_SIDED_PORTRAIT")]
			public const string TWO_LONG_EDGE;
			[CCode (cname = "CUPS_SIDES_TWO_SIDED_LANDSCAPE")]
			public const string TWO_SHORT_EDGE;
		}

		namespace Orientation {
			[CCode (cname = "3")]
			public const int PORTRAIT;
			[CCode (cname = "4")]
			public const int LANDSCAPE;
			[CCode (cname = "5")]
			public const int REVERSE_PORTRAIT;
			[CCode (cname = "6")]
			public const int REVERSE_LANDSCAPE;
		}
	}
}
