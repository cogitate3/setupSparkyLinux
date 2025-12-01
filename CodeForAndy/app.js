// 动态添加删除按钮样式
const style = document.createElement("style");
style.textContent = `
  .tweet {
    position: relative;
  }
  .delete-btn {
    position: absolute;
    top: 12px;
    right: 12px;
    background: #ff4444dd;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    transition: all 0.2s;
    font-family: system-ui;
    font-size: 0.9em;
    z-index: 10;
  }
  .delete-btn:hover {
    background: #cc0000;
    transform: scale(1.05);
  }
`;
document.head.appendChild(style);

// 推文数据数组
window.tweets = [
    {
        id: "1861272511809495448",
        created_at: "2024-11-25 23:55:22 -05:00",
        full_text: "介绍视频在这里\nhttps://t.co/l2hzg9K2jT",
        media: [],
        profile_image_url: "https://pbs.twimg.com/profile_images/554257566008483840/CzOgjPoY_normal.jpeg",
        name: "laike9m",
        screen_name: "laike9m_",
    },
    {
        id: "1863324233138631091",
        created_at: "2024-12-01 15:48:10 -05:00",
        full_text: "本来准备写，但是发现了一篇写的非常好的来自于共识粉碎机公众号的文章，研究的比我深入而且把我想说的都说了：https://t.co/sma75bKL6I\n安全赛道四大卷王PANW/CRWD/S/WIZ基本和我看法一致，平台化才是这个赛道的出路。\n再看下CRWD染指的细分赛道，六边形战士真不是吹的，所以贵有贵的道理 https://t.co/Y6HxzjbfwK",
        media: [
            {
                type: "photo",
                original: "https://pbs.twimg.com/media/GdvbVxmaQAAxyRo?format=jpg&name=orig",
            },
        ],
        profile_image_url: "https://pbs.twimg.com/profile_images/1861495483161812994/YOOroU9L_normal.jpg",
        name: "Hao Huang",
        screen_name: "hhuang",
    },
];

// 渲染推文
function renderTweets() {
    const container = document.querySelector('.tweet-container');
    container.innerHTML = ''; // Clear existing tweets
    window.tweets.forEach(tweet => {
        const tweetElement = document.createElement('div');
        tweetElement.className = 'tweet';
        tweetElement.dataset.tweetId = tweet.id;

        const content = `
            <div class="tweet-header">
                <img class="profile-image" src="${tweet.profile_image_url}" alt="${tweet.name}">
                <div class="user-info">
                    <div class="user-name">${tweet.name}</div>
                    <div class="screen-name">@${tweet.screen_name}</div>
                </div>
            </div>
            <div class="tweet-text">${tweet.full_text}</div>
            ${tweet.media.length > 0 ? `
                <div class="tweet-media">
                    ${tweet.media.map(media => 
                        media.type === 'photo' 
                            ? `<img src="${media.original}" alt="Media">`
                            : media.type === 'video'
                                ? `<video controls src="${media.original}"></video>`
                                : ''
                    ).join('')}
                </div>
            ` : ''}
            <div class="tweet-footer">
                ${new Date(tweet.created_at).toLocaleString()}
            </div>
        `;
        
        tweetElement.innerHTML = content;
        container.appendChild(tweetElement);
    });
    addDeleteButtons();
}

// 初始化删除功能
document.addEventListener("DOMContentLoaded", () => {
  const container = document.querySelector(".tweet-container");

  // 为所有推文添加删除按钮
  function addDeleteButtons() {
    document.querySelectorAll(".tweet").forEach((tweet) => {
      if (!tweet.querySelector(".delete-btn")) {
        const btn = document.createElement("button");
        btn.className = "delete-btn";
        btn.textContent = "× 删除";
        btn.dataset.tweetId = tweet.dataset.tweetId;
        tweet.appendChild(btn);
      }
    });
  }

  // 删除功能实现
  container.addEventListener("click", function (e) {
    if (!e.target.matches(".delete-btn")) return;

    const tweetElement = e.target.closest(".tweet");
    const tweetId = tweetElement.dataset.tweetId;

    // 带动画移除DOM元素
    tweetElement.style.transition = "opacity 0.3s";
    tweetElement.style.opacity = "0";
    setTimeout(() => tweetElement.remove(), 300);

    // 从tweets数组中移除
    const index = window.tweets.findIndex((t) => t.id === tweetId);
    if (index > -1) {
      window.tweets.splice(index, 1);
      console.log("已删除推文，当前剩余:", window.tweets.length);
    }
  });

  // 页面加载完成后渲染推文
  renderTweets();
});
