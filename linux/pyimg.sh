#!/bin/bash

# 全局变量声明
declare -g filename="" quantity="" url=""

# 颜色定义
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# 预设API接口
declare -A API_LIST=(
    [1]="https://www.loliapi.com/bg/"
    [2]="https://api.yimian.xyz/img?type=wallpaper"
    [3]="https://img.paulzzh.tech/touhou/random"
    [4]="https://www.xzccc.com/api/acg/"
    [5]="http://img.xjh.me/random_img.php?type=bg"
    [6]="https://api.dongmanxingkong.com/suijitupian/acg/1080p/index.php"
)

show_help() {
    echo -e "\n${BOLD}Usage:${RESET}"
    echo "  ./pyimg.sh [options]"
    echo -e "\n${BOLD}Options:${RESET}"
    echo "  -u, --url       Specify image API URL"
    echo "  -n, --name      Set output filename prefix"
    echo "  -c, --count     Set number of images to download"
    echo "  -h, --help      Show this help message"
    echo "  -i, --interactive  Enter interactive mode"
    echo -e "\n${BOLD}Examples:${RESET}"
    echo "  ./pyimg.sh -n mypic -c 10 -u https://example.com/api"
    echo "  ./pyimg.sh --interactive"
}

show_logo() {
    clear
    echo "${BOLD}${YELLOW}"
    cat << "LOGO"
                                              ___           ___
     ___           __             ___        /  /\         /  /\
    /  /\         |  |\          /__/\      /  /::|       /  /::\
   /  /::\        |  |:|         \__\:\    /  /:|:|      /  /:/\:\
  /  /:/\:\       |  |:|         /  /::\  /  /:/|:|__   /  /:/  \:\
 /  /::\ \:\      |__|:|__    __/  /:/\/ /__/:/_|::::\ /__/:/_\_ \:\
/__/:/\:\_\:\     /  /::::\  /__/\/:/~~  \__\/  /~~/:/ \  \:\__/\_\/
\__\/  \:\/:/    /  /:/~~~~  \  \::/           /  /:/   \  \:\ \:\
     \  \::/    /__/:/        \  \:\          /  /:/     \  \:\/:/
      \__\/     \__\/          \__\/         /__/:/       \  \::/
                                             \__\/         \__\/
                                                --By Lrst_6963
LOGO
    echo "${RESET}"
}

validate_number() {
    local num="$1"
    [[ "$num" =~ ^[1-9][0-9]*$ ]] || {
        echo -e "${RED}Error: Please enter a valid positive integer${RESET}"
        return 1
    }
}

check_dependencies() {
    # 检查wget
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}Installing wget...${RESET}"
        if [[ $(command -v apt-get) ]]; then
            sudo apt-get update && sudo apt-get install -y wget
        elif [[ $(command -v yum) ]]; then
            sudo yum install -y wget
        else
            echo -e "${RED}Error: Cannot install wget automatically. Please install it manually.${RESET}"
            exit 1
        fi
    fi

    # 检查ffmpeg
    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Error: ffmpeg is required but not installed.${RESET}"
        echo -e "Installation guide:"
        if [[ $(command -v apt-get) ]]; then
            echo "  sudo apt-get install ffmpeg"
        elif [[ $(command -v yum) ]]; then
            echo "  sudo yum install ffmpeg"
        else
            echo "  Install ffmpeg using your package manager"
        fi
        exit 1
    fi
}

download_images() {
    local count=1
    echo  # 初始空行分隔

    while [[ $count -le $quantity ]]; do
        temp_file="${filename}_${count}.tmp"
        final_file="${filename}_${count}.jpg"

        # 下载进度显示
        printf "\r\033[K${YELLOW}🚀 下载中: %d/%d${RESET}" "$count" "$quantity"

        # 下载到临时文件
        if ! wget --timeout=30 -q -O "$temp_file" "$url"; then
            printf "\r\033[K${RED}❌ 下载失败: %d/%d${RESET}\n" "$count" "$quantity"
            ((count++))
            continue
        fi

        # 转换进度显示
        printf "\r\033[K${YELLOW}🔄 转换中: %d/%d${RESET}" "$count" "$quantity"
        if ffmpeg -v error -i "$temp_file" -q:v 2 "$final_file" &> /dev/null; then
            rm -f "$temp_file"
            printf "\r\033[K${GREEN}✅ 已完成: %d/%d${RESET}" "$count" "$quantity"
        else
            printf "\r\033[K${RED}❌ 转换失败: %d/%d (原始文件保留: %s)${RESET}\n" "$count" "$quantity" "$temp_file"
        fi

        ((count++))
        sleep 0.1  # 保证显示流畅
    done

    echo -e "\n${BOLD}${GREEN}🎉 所有任务已完成！共成功 ${quantity} 张${RESET}"
}

interactive_mode() {
    show_logo
    
    # 获取文件名
    while :; do
        read -rp "Enter filename prefix: " filename
        [[ -n "$filename" ]] && break
        echo -e "${RED}Error: Filename cannot be empty${RESET}"
    done

    # 获取下载数量
    while :; do
        read -rp "Enter number of images to download: " quantity
        validate_number "$quantity" && break
    done

    # API选择菜单
    echo -e "\n${BOLD}Available APIs:${RESET}"
    for key in "${!API_LIST[@]}"; do
        echo "  ${key}) ${API_LIST[$key]}"
    done
    echo -e "  0) Enter custom URL"

    while :; do
        read -rp "Select API (number) or enter 0 for custom: " choice
        if [[ "$choice" == 0 ]]; then
            read -rp "Enter custom URL: " url
            [[ -n "$url" ]] && break
            echo -e "${RED}Error: URL cannot be empty${RESET}"
        elif [[ -n "${API_LIST[$choice]}" ]]; then
            url="${API_LIST[$choice]}"
            break
        else
            echo -e "${RED}Invalid selection, try again${RESET}"
        fi
    done

    # 确认信息
    echo -e "\n${BOLD}Summary:${RESET}"
    echo "  Filename: ${filename}"
    echo "  Quantity: ${quantity}"
    echo "  API URL: ${url}"
    echo -e "\nPress any key to start downloading (Ctrl+C to cancel)"
    read -n1 -s
    
    check_dependencies
    download_images
}

# 参数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            url="$2"
            shift 2
            ;;
        -n|--name)
            filename="$2"
            shift 2
            ;;
        -c|--count)
            quantity="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--interactive)
            interactive_mode
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            show_help
            exit 1
            ;;
    esac
done

# 非交互模式参数验证
if [[ -z "$url" || -z "$filename" || -z "$quantity" ]]; then
    echo -e "${RED}Error: Missing required parameters${RESET}"
    show_help
    exit 1
fi

validate_number "$quantity" || exit 1
check_dependencies
download_images
