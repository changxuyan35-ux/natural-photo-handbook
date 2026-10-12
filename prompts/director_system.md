 <!-- 姿态半透明轮廓 -->
    <div class="pose-silhouette" id="poseSilhouette">
      <!-- 默认姿态：侧身托腮姿态矢量简图 -->
      <svg viewBox="0 0 100 100">
        <circle cx="50" cy="25" r="12" />
        <path d="M50 37 L50 65 M50 65 L35 95 M50 65 L65 95 M50 45 L30 55 M50 45 L70 35 L60 25" />
      </svg>
    </div>

    <!-- 模拟 AI 感知状态 -->
    <div class="status-pill">
      <span class="status-dot"></span>
      <span id="aiTip">姿态匹配度: 91% (极佳) | 建议光线: 柔光</span>
    </div>
  </div>

  <!-- 操作按钮面板 -->
  <div class="controls">
    <div class="btn-group">
      <button class="active" id="btnPose" onclick="togglePose()">姿态引导: 开</button>
      <button class="active" id="btnGrid" onclick="toggleGrid()">三分构图线: 开</button>
      <button onclick="switchTemplate()">切换姿势模板 ↻</button>
    </div>
    <button class="shutter-btn" onclick="takeSnapshot()">📷</button>
  </div>

  <!-- 隐藏的绘图 Canvas 用于保存照片 -->
  <canvas id="photoCanvas" style="display: none;"></canvas>

  <!-- 拍摄成果卡片 -->
  <div id="cardModal">
    < img id="capturedImage" alt="Captured" />
    <div class="card-footer">
      <span>LEICA M11 · 35mm</span>
      <span>f/1.4 · ISO 100</span>
    </div>
    <div style="margin-top: 10px; font-weight: bold; font-size: 0.9rem;">自然氛围感 · 捕捉完成</div>
  </div>

  <script>
    const video = document.getElementById('webcam');
    const canvas = document.getElementById('photoCanvas');
    const cardModal = document.getElementById('cardModal');
    const capturedImage = document.getElementById('capturedImage');
    const gridLines = document.getElementById('gridLines');
    const poseSilhouette = document.getElementById('poseSilhouette');
    const aiTip = document.getElementById('aiTip');

    // 1. 调用系统摄像头
    async function initCamera() {
      try {
        const stream = await navigator.mediaDevices.getUserMedia({ 
          video: { facingMode: "user" }, 
          audio: false 
        });
        video.srcObject = stream;
      } catch (err) {
        aiTip.innerText = "请允许摄像头权限以体验实时姿态指导";
      }
    }
    initCamera();

    // 2. 交互功能控制
    function toggleGrid() {
      const isVisible = gridLines.style.opacity !== '0';
      gridLines.style.opacity = isVisible ? '0' : '1';
      document.getElementById('btnGrid').innerText = isVisible ? '三分构图线: 关' : '三分构图线: 开';
      document.getElementById('btnGrid').classList.toggle('active', !isVisible);
    }

    function togglePose() {
      const isVisible = poseSilhouette.style.opacity !== '0';
      poseSilhouette.style.opacity = isVisible ? '0' : '1';
      document.getElementById('btnPose').innerText = isVisible ? '姿态引导: 关' : '姿态引导: 开';
      document.getElementById('btnPose').classList.toggle('active', !isVisible);
    }

    let currentTemplate = 0;
    const tips = [
      "姿态匹配度: 91% (极佳) | 建议: 侧头微托腮",
      "姿态匹配度: 87% (自然) | 建议: 双手插兜微倾",
      "姿态匹配度: 94% (极佳) | 建议: 慢步走动回眸"
    ];
    function switchTemplate() {
      currentTemplate = (currentTemplate + 1) % tips.length;
      aiTip.innerText = tips[currentTemplate];
    }

    // 3. 模拟快门抓拍并生成拍立得卡片
    function takeSnapshot() {
      canvas.width = video.videoWidth || 640;
      canvas.height = video.videoHeight || 480;
      const ctx = canvas.getContext('2d');
      // 镜像绘制保持与视觉一致
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

      capturedImage.src = canvas.toDataURL('image/png');
      cardModal.style.display = 'block';
      cardModal.scrollIntoView({ behavior: 'smooth' });
    }
  </script>
</body>
</html>
