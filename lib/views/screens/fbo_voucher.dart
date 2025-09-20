import 'package:areg_app/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../agent/common/common_appbar.dart';
import '../../common/shimmer_loader.dart'; // ✅ Import Global Shimmer
import '../../fbo_services/FBO_voucher_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VoucherHistoryScreen extends StatefulWidget {
  const VoucherHistoryScreen({super.key});

  @override
  _VoucherHistoryScreenState createState() => _VoucherHistoryScreenState();
}

class _VoucherHistoryScreenState extends State<VoucherHistoryScreen> {
  final VoucherService _voucherService = VoucherService();
  late Future<List<Map<String, dynamic>>> _vouchersFuture;
  String? userRole;
  bool _isLoading = false;

  Map<int, bool> isDownloading = {}; // ✅ Track download state
  Map<String, bool> isDownloadingTypeSpecific =
      {}; // Key format: "$orderId-type"

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _vouchersFuture = _voucherService.fetchVouchers();
  }

  Future<void> _downloadStatement(DateTime start, DateTime end) async {
    try {
      final String filePath = await _voucherService.downloadVoucher(
        0,
        format: "pdf",
        fromDate: start,
        toDate: end,
      );

      _voucherService.openFile(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Statement downloaded from $start to $end')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error downloading statement: $e')),
      );
    }
  }

  /// ✅ Fetch user role from shared preferences
  Future<void> _fetchUserRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString('role');
    });
  }

  /// ✅ Handle voucher download with loading indicator
  Future<void> _downloadVoucher(int orderId, String format, String type) async {
    setState(() {
      isDownloadingTypeSpecific["$orderId-$type"] = true;
    });

    try {
      String filePath =
          await _voucherService.downloadVoucher(orderId, format: format);
      print("✅ Voucher ($format) saved at: $filePath");
      _voucherService.openFile(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Voucher ($format) downloaded successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to download voucher.")),
      );
    }

    setState(() {
      isDownloadingTypeSpecific["$orderId-$type"] = false;
    });
  }

  /// ✅ Shimmer effect while loading data
  Widget _buildShimmerList() {
    return ListView.builder(
      itemCount: 6, // ✅ Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(height: 20, width: 100), // ✅ Fake Order ID
                const SizedBox(height: 10),
                const ShimmerLoader(height: 14), // ✅ Fake Type
                const ShimmerLoader(height: 14), // ✅ Fake Quantity
                const ShimmerLoader(height: 14, width: 150), // ✅ Fake Status
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake PDF Button
                    const SizedBox(width: 10),
                    const Expanded(child: ShimmerLoader(height: 40)),
                    // ✅ Fake Excel Button
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _selectedTabIndex = 0; // 0 => Voucher, 1 => Statement
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppbar(title: "Get Your Vouchers"),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTopTab("Voucher", 0),
                _buildTopTab("Statement Download", 1),
              ],
            ),
          ),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildVoucherList()
                : _buildStatementDownloadTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTab(String label, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.white,
            borderRadius: BorderRadius.horizontal(
              left: Radius.circular(index == 0 ? 12 : 0),
              right: Radius.circular(index == 1 ? 12 : 0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoucherList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _vouchersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList();
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/empty.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                const SizedBox(height: 20),
                const Text(
                  "No completed orders yet!",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> vouchers = snapshot.data!;

        return ListView.builder(
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            int orderId = voucher["order_id"];

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoucherItem("Order ID:", voucher["order_id"].toString()),
                  _buildVoucherItem("Type:", voucher["type"]),
                  _buildVoucherItem("Quantity:", "kg ${voucher["quantity"]}".toString()),
                  _buildVoucherItem("Status:", voucher["status"]),
                //  _buildVoucherItem("Agreed Price:", "₹${voucher["agreed_price"]}"),
                  _buildVoucherItem("User Name:", voucher["user_name"]),
                  _buildVoucherItem("Address:", voucher["address"], multiline: true),
                  _buildVoucherItem("User Contact:", voucher["user_contact"]),
                  _buildVoucherItem("Amount:", "₹${voucher["amount"]}"),
                  _buildVoucherItem("Pickup Date:", voucher["date"]),
                  _buildVoucherItem("Time:", voucher["time"]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              isDownloadingTypeSpecific["$orderId-pdf"] == true
                                  ? null
                                  : () =>
                                      _downloadVoucher(orderId, "pdf", "pdf"),
                          // Passing 'pdf' as the 'type' argument

                          icon: isDownloadingTypeSpecific["$orderId-pdf"] ==
                                  true
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Image(
                                  image:
                                      AssetImage('assets/icon/pdf.png'),
                                  width: 24,
                                  height: 24,

                                ),

                          label: Text(
                            isDownloading[orderId] == true
                                ? "Downloading..."
                                : "PDF",
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD32027)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (userRole == "agent")
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                isDownloadingTypeSpecific["$orderId-excel"] ==
                                        true
                                    ? null
                                    : () => _downloadVoucher(
                                        orderId, "excel", "excel"),

                            icon: isDownloadingTypeSpecific["$orderId-excel"] ==
                                    true
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Image(
                              image:
                              AssetImage('assets/icon/excel.png'),
                              width: 24,
                              height: 24,

                            ),

                            label: Text(
                              isDownloading[orderId] == true
                                  ? "Downloading..."
                                  : "Excel",
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor:  Color(0xFF6FA006)),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatementDownloadTab() {
    String? _selectedOption;
    DateTime? _startDate;
    DateTime? _endDate;

    final List<String> options = [
      'Last 30 Days',
      'Last 90 Days',
      'Last 180 Days',
      'Last 365 Days',
    ];

    Future<void> _pickDate(BuildContext context, bool isStart) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      }
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Radio options
              ...options.map((option) => Column(
                    children: [
                      RadioListTile<String>(
                        title: Text(
                          option,
                          style: TextStyle(
                              color: AppColors.secondaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                        value: option,
                        groupValue: _selectedOption,
                        activeColor: AppColors.secondaryColor,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  )),

              const SizedBox(height: 10),

              // Date pickers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(context, true).then((_) {
                        setState(() {});
                      }),
                      icon: SizedBox(
                        width: 20, // control width
                        height: 20, // control height
                        child: Image.asset('assets/icon/calender.png'),
                      ),
                      label: Text(
                        _startDate == null
                            ? 'Start from'
                            : '${_startDate!.toLocal()}'.split(' ')[0],
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color:AppColors.secondaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(context, false).then((_) {
                        setState(() {});
                      }),
                      icon: SizedBox(
                        width: 20, // control width
                        height: 20, // control height
                        child: Image.asset('assets/icon/calender.png'),
                      ),
                      label: Text(
                        _endDate == null
                            ? 'End on'
                            : '${_endDate!.toLocal()}'.split(' ')[0],
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: AppColors.secondaryColor),
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(), // Pushes the download button to the bottom
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        DateTime now = DateTime.now();
                        DateTime start;
                        DateTime end = now;

                        if (_selectedOption != null) {
                          switch (_selectedOption) {
                            case 'Last 30 Days':
                              start = now.subtract(const Duration(days: 30));
                              break;
                            case 'Last 90 Days':
                              start = now.subtract(const Duration(days: 90));
                              break;
                            case 'Last 180 Days':
                              start = now.subtract(const Duration(days: 180));
                              break;
                            case 'Last 365 Days':
                              start = now.subtract(const Duration(days: 365));
                              break;
                            default:
                              start = now;
                          }
                        } else if (_startDate != null && _endDate != null) {
                          start = _startDate!;
                          end = _endDate!;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a date range')),
                          );
                          return;
                        }

                        setState(() => _isLoading = true);
                        await _downloadStatement(start, end);
                        setState(() => _isLoading = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isLoading ? Colors.grey : AppColors.secondaryColor,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 70),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Download",
                        style: TextStyle(color: Colors.white),
                      ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoucherItem(String title, String value,
      {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppColors.secondaryColor,
                height: multiline ? 1.4 : 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
