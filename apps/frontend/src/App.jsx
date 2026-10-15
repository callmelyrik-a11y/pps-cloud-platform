export default function App() {
  return (
    <main className="page">
      <header className="header"><span className="mark">PPS</span><span>조달 플랫폼 · AWS 클라우드 전환 실습</span></header>
      <section className="hero">
        <p className="eyebrow">Procurement Platform Prototype</p>
        <h1>클라우드 기반 조달 업무 플랫폼</h1>
        <p>React · FastAPI · EKS · Aurora · CloudFront 아키텍처를 검증하기 위한 교육용 프로토타입입니다.</p>
      </section>
      <div className="cards">
        <article><h2>기관 관리</h2><p>Organization Service</p><small>API 초안: GET /api/organizations</small></article>
        <article><h2>입찰공고</h2><p>Notice Service</p><small>API 초안: GET /api/notices</small></article>
      </div>
      <footer>교육 및 설계 검증 목적 · 실제 조달청 운영 시스템과 무관</footer>
    </main>
  );
}
