#include <iostream>
#include <vector>
#include <thread>
#include <atomic>
#include <cmath>
#include <chrono>

// Hàm tính tổng các ước thực sự của n (chỉ kiểm tra các số lẻ)
bool isOddPerfect(unsigned long long n) {
    if (n <= 1 || n % 2 == 0) return false;

    unsigned long long sum = 1;
    unsigned long long sqrt_n = std::sqrt(n);

    for (unsigned long long i = 3; i <= sqrt_n; i += 2) {
        if (n % i == 0) {
            sum += i;
            unsigned long long pair = n / i;
            if (i != pair) {
                sum += pair;
            }
        }
    }
    return sum == n;
}

// Hàm chạy cho từng luồng (Worker)
void workerRange(unsigned long long start, unsigned long long end,
                 std::atomic<bool>& found, std::atomic<unsigned long long>& result,
                 std::atomic<unsigned long long>& current_checked) {
    if (start % 2 == 0) start++;

    for (unsigned long long n = start; n <= end; n += 2) {
        if (found) return;

        // Cập nhật tiến độ định kỳ mỗi 10,000 lần kiểm tra để tránh nghẽn luồng in ấn
        if (n % 10000 == 1) {
            current_checked.store(n, std::memory_order_relaxed);
        }

        if (isOddPerfect(n)) {
            result = n;
            found = true;
            return;
        }
    }
}

int main() {
    std::cout << "=== Chuong trinh tim so hoan hao le (Co hien thi tien do) ===\n";

    unsigned int hardware_threads = std::thread::hardware_concurrency();
    unsigned int num_threads = (hardware_threads > 0) ? hardware_threads : 4;

    std::cout << "[Thong tin] Su dung " << num_threads << " CPU threads.\n";

    unsigned long long range_start = 3;
    unsigned long long range_end   = 1000000000ULL; // Tăng lên 1 tỷ để thấy rõ quá trình chạy

    std::cout << "[Thong tin] Quet tu " << range_start << " den " << range_end << "...\n\n";

    auto start_time = std::chrono::high_resolution_clock::now();

    std::atomic<bool> found(false);
    std::atomic<unsigned long long> result(0);
    std::atomic<unsigned long long> current_checked(range_start);

    unsigned long long total_span = range_end - range_start;
    unsigned long long chunk_size = total_span / num_threads;

    std::vector<std::thread> threads;
    threads.reserve(num_threads);

    for (unsigned int i = 0; i < num_threads; ++i) {
        unsigned long long s = range_start + i * chunk_size;
        unsigned long long e = (i == num_threads - 1) ? range_end : s + chunk_size - 1;

        threads.emplace_back(workerRange, s, e, std::ref(found), std::ref(result), std::ref(current_checked));
    }

    // Luồng giám sát để in tiến độ ra màn hình mỗi giây
    while (!found) {
        // Kiểm tra xem tất cả các luồng đã chạy xong chưa
        bool all_done = true;
        for (auto& th : threads) {
            // Lưu ý: Trong C++ thuần ta dùng joinable để kiểm tra trạng thái
        }

        unsigned long long current = current_checked.load(std::memory_order_relaxed);
        std::cout << "\r[Dang chay] Dang kiem tra toi so: " << current << std::flush;

        // Thoát vòng lặp giám sát nếu đã quét hết dải số (có thể kiểm tra điều kiện hoàn thành)
        if (current >= range_end - 10000) break;

        std::this_thread::sleep_for(std::chrono::milliseconds(200));
    }

    // Chờ tất cả các luồng kết thúc hẳn
    for (auto& th : threads) {
        th.join();
    }

    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();

    std::cout << "\n\n[Hoan tat] Thoi gian thuc thi: " << duration << " ms\n";

    if (found) {
        std::cout << ">>> Tim thay so hoan hao le: " << result.load() << "\n";
    } else {
        std::cout << ">>> Khong tim thay so hoan hao le nao trong pham vi nay.\n";
    }

    return 0;
}