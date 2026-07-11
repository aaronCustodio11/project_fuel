/* =========================================================
   FLEET SENSE — SCRIPT
   ========================================================= */

document.addEventListener('DOMContentLoaded', () => {

  /* ---------- Sticky navbar background on scroll ---------- */
  const navbar = document.getElementById('navbar');
  const onScroll = () => {
    if (window.scrollY > 24) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }
  };
  onScroll();
  window.addEventListener('scroll', onScroll, { passive: true });

  /* ---------- Mobile hamburger menu ---------- */
  const hamburger = document.getElementById('hamburger');
  const mobileMenu = document.getElementById('mobileMenu');

  hamburger.addEventListener('click', () => {
    mobileMenu.classList.toggle('open');
    hamburger.classList.toggle('open');
  });

  mobileMenu.querySelectorAll('a, button').forEach((el) => {
    el.addEventListener('click', () => {
      mobileMenu.classList.remove('open');
      hamburger.classList.remove('open');
    });
  });

  /* ---------- Active nav link on scroll ---------- */
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-link');

  const setActiveLink = () => {
    let currentId = sections[0]?.id;
    const scrollPos = window.scrollY + 140;

    sections.forEach((section) => {
      if (scrollPos >= section.offsetTop) {
        currentId = section.id;
      }
    });

    navLinks.forEach((link) => {
      link.classList.toggle('active', link.getAttribute('href') === `#${currentId}`);
    });
  };
  setActiveLink();
  window.addEventListener('scroll', setActiveLink, { passive: true });

  /* ---------- Scroll reveal animations ---------- */
  const revealEls = document.querySelectorAll('.reveal-up');

  const revealObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          revealObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15, rootMargin: '0px 0px -40px 0px' }
  );

  revealEls.forEach((el) => revealObserver.observe(el));

  /* ---------- Animated statistic counters ---------- */
  const statNumbers = document.querySelectorAll('.stat-number[data-target]');

  const animateCounter = (el) => {
    const target = parseFloat(el.dataset.target);
    const suffix = el.dataset.suffix || '';
    const decimals = el.dataset.decimal ? parseInt(el.dataset.decimal, 10) : 0;
    const duration = 1600;
    const start = performance.now();

    const tick = (now) => {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3); // ease-out-cubic
      const value = target * eased;
      el.textContent = value.toFixed(decimals) + suffix;

      if (progress < 1) {
        requestAnimationFrame(tick);
      } else {
        el.textContent = target.toFixed(decimals) + suffix;
      }
    };
    requestAnimationFrame(tick);
  };

  const statObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          animateCounter(entry.target);
          statObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.5 }
  );

  statNumbers.forEach((el) => statObserver.observe(el));

  /* ---------- Button ripple effect ---------- */
  document.querySelectorAll('.ripple').forEach((btn) => {
    btn.addEventListener('click', function (e) {
      const rect = this.getBoundingClientRect();
      const ripple = document.createElement('span');
      const size = Math.max(rect.width, rect.height);
      ripple.className = 'ripple-effect';
      ripple.style.width = ripple.style.height = `${size}px`;
      ripple.style.left = `${e.clientX - rect.left - size / 2}px`;
      ripple.style.top = `${e.clientY - rect.top - size / 2}px`;
      this.appendChild(ripple);
      setTimeout(() => ripple.remove(), 650);
    });
  });

  /* ---------- Smooth scroll for in-page anchors ---------- */
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', (e) => {
      const targetId = anchor.getAttribute('href');
      if (targetId.length < 2) return;
      const target = document.querySelector(targetId);
      if (target) {
        e.preventDefault();
        const offset = 84;
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  /* ---------- Contact form (demo submission, no backend) ---------- */
  const contactForm = document.getElementById('contactForm');
  const formSuccess = document.getElementById('formSuccess');

  if (contactForm) {
    contactForm.addEventListener('submit', (e) => {
      e.preventDefault();
      formSuccess.classList.add('show');
      contactForm.reset();
      setTimeout(() => formSuccess.classList.remove('show'), 4000);
    });
  }

  /* ---------- Hero Subscribe Now -> scroll to Subscription ---------- */
  const heroSubscribeBtn = document.getElementById('heroSubscribeBtn');
  if (heroSubscribeBtn) {
    heroSubscribeBtn.addEventListener('click', () => {
      const target = document.getElementById('subscription');
      if (target) {
        const offset = 84;
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  }

  /* ---------- Login button redirect ---------- */
  const loginBtn = document.getElementById('loginBtn');
  if (loginBtn) {
    loginBtn.addEventListener('click', () => {
      window.location.href = 'https://fleetsense.web.app/';
    });
  }

  /* ---------- Download modal ---------- */
  const downloadModal = document.getElementById('downloadModal');
  const downloadModalClose = document.getElementById('downloadModalClose');
  const downloadStartBtn = document.getElementById('downloadStartBtn');
  const downloadDoneBtn = document.getElementById('downloadDoneBtn');
  const downloadConfirm = document.getElementById('downloadConfirm');
  const downloadLoading = document.getElementById('downloadLoading');
  const downloadDoneStep = document.getElementById('downloadDone');
  const downloadProgressFill = document.getElementById('downloadProgressFill');
  const downloadProgressText = document.getElementById('downloadProgressText');
  const downloadAllSteps = [downloadConfirm, downloadLoading, downloadDoneStep];
  const APK_PATH = 'app/FleetSense.apk';

  const openDownloadModal = () => {
    downloadAllSteps.forEach((s) => s.classList.add('modal-step-hidden'));
    downloadConfirm.classList.remove('modal-step-hidden');
    downloadProgressFill.style.width = '0%';
    downloadProgressText.textContent = 'Starting…';
    downloadModal.classList.add('open');
    downloadModal.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
  };

  const closeDownloadModal = () => {
    downloadModal.classList.remove('open');
    downloadModal.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
  };

  document.getElementById('downloadBtn').addEventListener('click', openDownloadModal);
  const mobileDownloadBtn = document.getElementById('mobileDownloadBtn');
  if (mobileDownloadBtn) mobileDownloadBtn.addEventListener('click', openDownloadModal);

  downloadModalClose.addEventListener('click', closeDownloadModal);
  downloadModal.addEventListener('click', (e) => {
    if (e.target === downloadModal) closeDownloadModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && downloadModal.classList.contains('open')) closeDownloadModal();
  });

  downloadDoneBtn.addEventListener('click', closeDownloadModal);

  downloadStartBtn.addEventListener('click', () => {
    downloadAllSteps.forEach((s) => s.classList.add('modal-step-hidden'));
    downloadLoading.classList.remove('modal-step-hidden');
    downloadProgressFill.style.width = '0%';
    downloadProgressText.textContent = 'Starting…';

    const xhr = new XMLHttpRequest();
    xhr.open('GET', APK_PATH, true);
    xhr.responseType = 'blob';

    xhr.onprogress = (e) => {
      if (e.lengthComputable) {
        const pct = Math.round((e.loaded / e.total) * 100);
        downloadProgressFill.style.width = `${pct}%`;
        downloadProgressText.textContent = `${pct}%`;
      } else {
        downloadProgressText.textContent = 'Downloading…';
      }
    };

    xhr.onload = () => {
      if (xhr.status === 200) {
        const blob = xhr.response;
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'FleetSense.apk';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      }
      downloadProgressFill.style.width = '100%';
      downloadProgressText.textContent = 'Complete!';

      setTimeout(() => {
        downloadAllSteps.forEach((s) => s.classList.add('modal-step-hidden'));
        downloadDoneStep.classList.remove('modal-step-hidden');
      }, 500);
    };

    xhr.onerror = () => {
      downloadProgressText.textContent = 'Download failed. Please try again.';
      setTimeout(closeDownloadModal, 2500);
    };

    xhr.send();
  });

  /* ---------- Subscribe / checkout modal ---------- */
  const subscribeModal = document.getElementById('subscribeModal');
  const modalClose = document.getElementById('modalClose');
  const modalProgress = document.getElementById('modalProgress');

  const stepPayment = document.getElementById('stepPayment');
  const stepProcessing = document.getElementById('stepProcessing');
  const stepWelcome = document.getElementById('stepWelcome');
  const stepAccount = document.getElementById('stepAccount');
  const stepWarehouse = document.getElementById('stepWarehouse');
  const stepSuccess = document.getElementById('stepSuccess');
  const allSteps = [stepPayment, stepProcessing, stepWelcome, stepAccount, stepWarehouse, stepSuccess];

  const modalPlanName = document.getElementById('modalTitle');
  const modalPlanPrice = document.querySelector('.modal-plan-price');
  const welcomePlanLabel = document.getElementById('welcomePlanLabel');
  const successPlanLabel = document.getElementById('successPlanLabel');

  const checkoutForm = document.getElementById('checkoutForm');
  const checkoutError = document.getElementById('checkoutError');
  const cardNumberInput = document.getElementById('cardNumber');
  const cardExpiryInput = document.getElementById('cardExpiry');
  const cardCvvInput = document.getElementById('cardCvv');
  const agreeTerms = document.getElementById('agreeTerms');
  const payBtn = document.getElementById('payBtn');

  const processingTitle = document.getElementById('processingTitle');
  const processingNote = document.getElementById('processingNote');
  const welcomeContinueBtn = document.getElementById('welcomeContinueBtn');

  const accountForm = document.getElementById('accountForm');
  const accountError = document.getElementById('accountError');

  const warehouseForm = document.getElementById('warehouseForm');
  const warehouseError = document.getElementById('warehouseError');
  const warehouseList = document.getElementById('warehouseList');
  const addWarehouseBtn = document.getElementById('addWarehouseBtn');

  const redirectBar = document.getElementById('redirectBar');
  const continueBtn = document.getElementById('continueBtn');

  const REDIRECT_URL = 'https://fleetsense.web.app/';
  let redirectTimeout = null;

  /* stage order used to drive the progress stepper */
  const STAGE_ORDER = ['payment', 'account', 'warehouse', 'done'];
  const STEP_TO_STAGE = {
    payment: 'payment',
    account: 'account',
    warehouse: 'warehouse',
    done: 'done',
  };

  const setProgress = (stageKey) => {
    const currentIndex = STAGE_ORDER.indexOf(stageKey);
    modalProgress.querySelectorAll('.progress-dot').forEach((dot) => {
      const dotIndex = STAGE_ORDER.indexOf(dot.dataset.stage);
      dot.classList.remove('active', 'done');
      if (dotIndex < currentIndex) dot.classList.add('done');
      if (dotIndex === currentIndex) dot.classList.add('active');
    });
  };

  const showStep = (stepEl, stageKey) => {
    allSteps.forEach((s) => s.classList.add('modal-step-hidden'));
    stepEl.classList.remove('modal-step-hidden');
    if (stageKey) setProgress(stageKey);
  };

  const resetModal = () => {
    checkoutForm.reset();
    accountForm.reset();
    warehouseForm.reset();

    clearAllFieldErrors(checkoutForm);
    clearAllFieldErrors(accountForm);

    checkoutError.classList.remove('show');
    checkoutError.textContent = '';
    accountError.classList.remove('show');
    accountError.textContent = '';
    warehouseError.classList.remove('show');
    warehouseError.textContent = '';

    payBtn.disabled = false;
    payBtn.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><rect x="2" y="5" width="20" height="14" rx="2" stroke="currentColor" stroke-width="1.6"/><path d="M2 10H22" stroke="currentColor" stroke-width="1.6"/></svg>
      Pay & Subscribe`;
    document.querySelector('#stepAccount .btn-primary').disabled = true;
    document.getElementById('finishSetupBtn').disabled = true;

    /* collapse warehouse list back down to a single empty entry */
    const entries = warehouseList.querySelectorAll('.warehouse-entry');
    entries.forEach((entry, i) => { if (i > 0) entry.remove(); });

    redirectBar.style.width = '0%';
    if (redirectTimeout) clearTimeout(redirectTimeout);
    showStep(stepPayment, 'payment');
    checkPaymentForm();
  };

  const openModal = (planName, planPrice) => {
    modalPlanName.textContent = `${planName} Plan`;
    welcomePlanLabel.textContent = planName;
    const priceMatch = planPrice.match(/^([₱$])([\d,]+)\/(\w+)$/);
    if (priceMatch) {
      modalPlanPrice.innerHTML = `${priceMatch[1]}${priceMatch[2]}<small>/${priceMatch[3]}</small>`;
    } else {
      modalPlanPrice.textContent = planPrice;
    }
    resetModal();
    subscribeModal.classList.add('open');
    subscribeModal.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
  };

  const closeModal = () => {
    subscribeModal.classList.remove('open');
    subscribeModal.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
    if (redirectTimeout) clearTimeout(redirectTimeout);
  };

  document.querySelectorAll('.js-subscribe-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
      openModal(btn.dataset.plan || 'Fleet Sense', btn.dataset.price || '');
    });
  });

  modalClose.addEventListener('click', closeModal);
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && subscribeModal.classList.contains('open')) closeModal();
  });

  /* -- card input formatting -- */
  cardNumberInput.addEventListener('input', () => {
    let digits = cardNumberInput.value.replace(/\D/g, '').slice(0, 16);
    cardNumberInput.value = digits.replace(/(.{4})/g, '$1 ').trim();
  });

  cardExpiryInput.addEventListener('input', () => {
    let digits = cardExpiryInput.value.replace(/\D/g, '').slice(0, 4);
    if (digits.length >= 3) {
      cardExpiryInput.value = `${digits.slice(0, 2)}/${digits.slice(2)}`;
    } else {
      cardExpiryInput.value = digits;
    }
  });

  cardCvvInput.addEventListener('input', () => {
    cardCvvInput.value = cardCvvInput.value.replace(/\D/g, '').slice(0, 4);
  });

  /* -- inline error helpers -- */
  const setFieldError = (fieldId, message) => {
    const errorEl = document.getElementById(`${fieldId}Error`);
    const field = document.getElementById(fieldId);
    if (!errorEl) return;
    if (message) {
      errorEl.textContent = message;
      errorEl.classList.add('show');
      if (field) field.closest('.form-group')?.classList.add('input-error');
    } else {
      errorEl.textContent = '';
      errorEl.classList.remove('show');
      if (field) field.closest('.form-group')?.classList.remove('input-error');
    }
  };

  const clearAllFieldErrors = (form) => {
    form.querySelectorAll('.field-error').forEach((el) => {
      el.textContent = '';
      el.classList.remove('show');
    });
    form.querySelectorAll('.form-group.input-error').forEach((el) => {
      el.classList.remove('input-error');
    });
  };

  /* -- Step 1: payment form inline validation + submit -- */
  const checkPaymentForm = () => {
    const cardName = document.getElementById('cardName').value.trim();
    const cardNumberDigits = cardNumberInput.value.replace(/\D/g, '');
    const expiry = cardExpiryInput.value.trim();
    const cvv = cardCvvInput.value.trim();
    const email = document.getElementById('billingEmail').value.trim();
    const expiryValid = /^(0[1-9]|1[0-2])\/\d{2}$/.test(expiry);
    const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    const valid = cardName && cardNumberDigits.length === 16 && expiryValid && cvv.length >= 3 && emailValid && agreeTerms.checked;
    payBtn.disabled = !valid;
    return valid;
  };

  const validatePaymentField = (fieldId) => {
    switch (fieldId) {
      case 'cardName':
        setFieldError('cardName', document.getElementById('cardName').value.trim() ? '' : 'Cardholder name is required');
        break;
      case 'billingEmail': {
        const v = document.getElementById('billingEmail').value.trim();
        setFieldError('billingEmail', !v ? 'Email is required' : /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) ? '' : 'Enter a valid email address');
        break;
      }
      case 'cardNumber': {
        const d = cardNumberInput.value.replace(/\D/g, '');
        setFieldError('cardNumber', !d ? 'Card number is required' : d.length < 16 ? 'Enter a valid 16-digit card number' : '');
        break;
      }
      case 'cardExpiry': {
        const v = cardExpiryInput.value.trim();
        setFieldError('cardExpiry', !v ? 'Expiry date is required' : /^(0[1-9]|1[0-2])\/\d{2}$/.test(v) ? '' : 'Use MM/YY format');
        break;
      }
      case 'cardCvv': {
        const v = cardCvvInput.value.trim();
        setFieldError('cardCvv', !v ? 'CVV is required' : v.length < 3 ? 'Enter a valid CVV' : '');
        break;
      }
      case 'agreeTerms':
        setFieldError('agreeTerms', agreeTerms.checked ? '' : 'You must accept the Terms and Conditions');
        break;
    }
    checkPaymentForm();
  };

  document.getElementById('cardName').addEventListener('blur', () => validatePaymentField('cardName'));
  document.getElementById('billingEmail').addEventListener('blur', () => validatePaymentField('billingEmail'));
  cardNumberInput.addEventListener('input', () => validatePaymentField('cardNumber'));
  cardExpiryInput.addEventListener('input', () => validatePaymentField('cardExpiry'));
  cardCvvInput.addEventListener('input', () => validatePaymentField('cardCvv'));
  agreeTerms.addEventListener('change', () => validatePaymentField('agreeTerms'));

  document.getElementById('cardName').addEventListener('input', checkPaymentForm);
  document.getElementById('billingEmail').addEventListener('input', checkPaymentForm);

  checkoutForm.addEventListener('submit', (e) => {
    e.preventDefault();
    validatePaymentField('cardName');
    validatePaymentField('billingEmail');
    validatePaymentField('cardNumber');
    validatePaymentField('cardExpiry');
    validatePaymentField('cardCvv');
    validatePaymentField('agreeTerms');
    if (!checkPaymentForm()) return;

    payBtn.disabled = true;
    payBtn.textContent = 'Processing…';

    processingTitle.textContent = 'Verifying your payment…';
    processingNote.textContent = "Please don't close this window.";
    showStep(stepProcessing, 'payment');

    setTimeout(() => {
      processingTitle.textContent = 'Payment verified — finalizing…';
      processingNote.textContent = 'Almost there.';
    }, 900);

    setTimeout(() => {
      showStep(stepWelcome, 'payment');
    }, 1800);
  });

  /* -- Step 3: welcome -> account creation -- */
  welcomeContinueBtn.addEventListener('click', () => {
    showStep(stepAccount, 'account');
  });

  /* -- Step 4: account creation form -> warehouse locations -- */
  /* -- extension name N/A checkbox -- */
  const extensionName = document.getElementById('extensionName');
  const extensionNA = document.getElementById('extensionNA');
  extensionNA.addEventListener('change', () => {
    if (extensionNA.checked) {
      extensionName.value = '';
      extensionName.disabled = true;
    } else {
      extensionName.disabled = false;
    }
  });

  /* -- password requirements checklist + strength meter -- */
  const accountPasswordInput = document.getElementById('accountPassword');
  const pwChecklist = document.getElementById('pwChecklist');
  const pwStrengthFill = document.getElementById('pwStrengthFill');
  const pwStrengthLabel = document.getElementById('pwStrengthLabel');

  const PW_RULES = {
    length: (v) => v.length >= 8,
    upper: (v) => /[A-Z]/.test(v),
    lower: (v) => /[a-z]/.test(v),
    number: (v) => /[0-9]/.test(v),
    special: (v) => /[^A-Za-z0-9]/.test(v),
  };

  const checkPasswordStrength = (value) => {
    let passedCount = 0;
    pwChecklist.querySelectorAll('li').forEach((li) => {
      const rule = li.dataset.rule;
      const passed = PW_RULES[rule](value);
      li.classList.toggle('valid', passed);
      if (passed) passedCount += 1;
    });

    const pct = (passedCount / 5) * 100;
    pwStrengthFill.style.width = `${pct}%`;

    let label = 'Password strength';
    let color = '#D64545';
    if (value.length > 0) {
      if (passedCount <= 2) { label = 'Weak password'; color = '#D64545'; }
      else if (passedCount <= 4) { label = 'Fair password'; color = '#E8A93D'; }
      else { label = 'Strong password'; color = '#1E9E6B'; }
    }
    pwStrengthFill.style.background = color;
    pwStrengthLabel.textContent = label;

    return passedCount === 5;
  };

  accountPasswordInput.addEventListener('input', () => {
    checkPasswordStrength(accountPasswordInput.value);
  });

  const resetPasswordChecklist = () => {
    pwChecklist.querySelectorAll('li').forEach((li) => li.classList.remove('valid'));
    pwStrengthFill.style.width = '0%';
    pwStrengthLabel.textContent = 'Password strength';
  };

  /* -- account form inline validation -- */
  const checkAccountForm = () => {
    const firstName = document.getElementById('firstName').value.trim();
    const surname = document.getElementById('surname').value.trim();
    const company = document.getElementById('accountCompany').value.trim();
    const email = document.getElementById('accountEmail').value.trim();
    const password = document.getElementById('accountPassword').value;
    const confirmPassword = document.getElementById('confirmPassword').value;
    const emailValid = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
    const pwStrong = checkPasswordStrength(password);
    const pwdMatch = password === confirmPassword && password.length > 0;
    const valid = firstName && surname && company && emailValid && pwStrong && pwdMatch;
    document.querySelector('#stepAccount .btn-primary').disabled = !valid;
    return valid;
  };

  const validateAccountField = (fieldId) => {
    switch (fieldId) {
      case 'firstName':
        setFieldError('firstName', document.getElementById('firstName').value.trim() ? '' : 'First name is required');
        break;
      case 'surname':
        setFieldError('surname', document.getElementById('surname').value.trim() ? '' : 'Surname is required');
        break;
      case 'accountCompany':
        setFieldError('accountCompany', document.getElementById('accountCompany').value.trim() ? '' : 'Company is required');
        break;
      case 'accountEmail': {
        const v = document.getElementById('accountEmail').value.trim();
        setFieldError('accountEmail', !v ? 'Email is required' : /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v) ? '' : 'Enter a valid email address');
        break;
      }
      case 'accountPassword': {
        const pw = document.getElementById('accountPassword').value;
        setFieldError('accountPassword', !pw ? 'Password is required' : checkPasswordStrength(pw) ? '' : 'Meet all requirements below');
        break;
      }
      case 'confirmPassword': {
        const pw = document.getElementById('accountPassword').value;
        const cp = document.getElementById('confirmPassword').value;
        setFieldError('confirmPassword', !cp ? 'Confirm your password' : cp !== pw ? 'Passwords do not match' : '');
        break;
      }
    }
    checkAccountForm();
  };

  document.getElementById('firstName').addEventListener('blur', () => validateAccountField('firstName'));
  document.getElementById('firstName').addEventListener('input', checkAccountForm);
  document.getElementById('surname').addEventListener('blur', () => validateAccountField('surname'));
  document.getElementById('surname').addEventListener('input', checkAccountForm);
  document.getElementById('accountCompany').addEventListener('blur', () => validateAccountField('accountCompany'));
  document.getElementById('accountCompany').addEventListener('input', checkAccountForm);
  document.getElementById('accountEmail').addEventListener('blur', () => validateAccountField('accountEmail'));
  document.getElementById('accountEmail').addEventListener('input', checkAccountForm);
  accountPasswordInput.addEventListener('input', () => {
    checkPasswordStrength(accountPasswordInput.value);
    validateAccountField('accountPassword');
    validateAccountField('confirmPassword');
    checkAccountForm();
  });
  document.getElementById('confirmPassword').addEventListener('input', () => {
    validateAccountField('confirmPassword');
    checkAccountForm();
  });

  accountForm.addEventListener('submit', (e) => {
    e.preventDefault();
    validateAccountField('firstName');
    validateAccountField('surname');
    validateAccountField('accountCompany');
    validateAccountField('accountEmail');
    validateAccountField('accountPassword');
    validateAccountField('confirmPassword');
    if (!checkAccountForm()) return;

    showStep(stepWarehouse, 'warehouse');
    /* the warehouse step was hidden until now, so its map needs sizing/init once visible */
    requestAnimationFrame(() => {
      warehouseList.querySelectorAll('.warehouse-entry').forEach((entry) => {
        ensureMapInitialized(entry);
        wireWarehouseValidation(entry);
      });
    });
  });

  /* -- Step 5: warehouse locations (Leaflet map + Nominatim location search) -- */
  const DEFAULT_CENTER = [13.7565, 121.0583]; // Batangas City, Philippines
  const DEFAULT_ZOOM = 12;
  let warehouseMapCounter = 1; // 0 is used by the initial entry already in the HTML

  const debounce = (fn, delay) => {
    let timer = null;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), delay);
    };
  };

  const triggerWarehouseValidation = (entry) => {
    const nameInput = entry.querySelector('.warehouse-name');
    const locInput = entry.querySelector('.warehouse-location');
    nameInput.dispatchEvent(new Event('input', { bubbles: true }));
    locInput.dispatchEvent(new Event('input', { bubbles: true }));
  };

  const setEntryLocation = (entry, lat, lng, label) => {
    const locationInput = entry.querySelector('.warehouse-location');
    const latInput = entry.querySelector('.warehouse-lat');
    const lngInput = entry.querySelector('.warehouse-lng');
    locationInput.value = label;
    latInput.value = lat;
    lngInput.value = lng;

    const map = entry._leafletMap;
    if (!map) return;
    map.setView([lat, lng], 15);
    if (entry._leafletMarker) {
      entry._leafletMarker.setLatLng([lat, lng]);
    } else {
      entry._leafletMarker = L.marker([lat, lng], { draggable: true }).addTo(map);
      entry._leafletMarker.on('dragend', () => {
        const pos = entry._leafletMarker.getLatLng();
        reverseGeocode(entry, pos.lat, pos.lng);
      });
    }
    triggerWarehouseValidation(entry);
  };

  const reverseGeocode = async (entry, lat, lng) => {
    const locationInput = entry.querySelector('.warehouse-location');
    const latInput = entry.querySelector('.warehouse-lat');
    const lngInput = entry.querySelector('.warehouse-lng');
    latInput.value = lat;
    lngInput.value = lng;
    locationInput.value = 'Locating…';
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`);
      const data = await res.json();
      locationInput.value = data.display_name || `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    } catch (err) {
      locationInput.value = `${lat.toFixed(5)}, ${lng.toFixed(5)}`;
    }
  };

  const renderSuggestions = (entry, results) => {
    const box = entry.querySelector('.location-suggestions');
    box.innerHTML = '';

    if (!results.length) {
      box.innerHTML = '<div class="suggestion-empty">No matching locations found.</div>';
      box.classList.add('show');
      return;
    }

    results.forEach((result) => {
      const item = document.createElement('div');
      item.className = 'suggestion-item';
      item.textContent = result.display_name;
      item.addEventListener('mousedown', (e) => {
        e.preventDefault();
        setEntryLocation(entry, parseFloat(result.lat), parseFloat(result.lon), result.display_name);
        box.classList.remove('show');
      });
      box.appendChild(item);
    });
    box.classList.add('show');
  };

  const searchLocation = async (entry, query) => {
    const box = entry.querySelector('.location-suggestions');
    if (query.trim().length < 3) {
      box.classList.remove('show');
      return;
    }
    try {
      const res = await fetch(`https://nominatim.openstreetmap.org/search?format=json&addressdetails=0&limit=5&q=${encodeURIComponent(query)}`);
      const data = await res.json();
      renderSuggestions(entry, data);
    } catch (err) {
      box.innerHTML = '<div class="suggestion-empty">Search unavailable right now.</div>';
      box.classList.add('show');
    }
  };

  const wireLocationSearch = (entry) => {
    const locationInput = entry.querySelector('.warehouse-location');
    const box = entry.querySelector('.location-suggestions');
    const debouncedSearch = debounce((q) => searchLocation(entry, q), 400);

    locationInput.addEventListener('input', () => debouncedSearch(locationInput.value));
    locationInput.addEventListener('focus', () => {
      if (box.children.length) box.classList.add('show');
    });
    locationInput.addEventListener('blur', () => {
      setTimeout(() => box.classList.remove('show'), 150);
    });
  };

  const ensureMapInitialized = (entry) => {
    if (entry.dataset.mapInit === 'true' || typeof L === 'undefined') return;
    const mapId = entry.querySelector('.warehouse-map').id;
    const map = L.map(mapId, { attributionControl: false }).setView(DEFAULT_CENTER, DEFAULT_ZOOM);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
    }).addTo(map);

    map.on('click', (e) => {
      reverseGeocode(entry, e.latlng.lat, e.latlng.lng);
      if (entry._leafletMarker) {
        entry._leafletMarker.setLatLng(e.latlng);
      } else {
        entry._leafletMarker = L.marker(e.latlng, { draggable: true }).addTo(map);
        entry._leafletMarker.on('dragend', () => {
          const pos = entry._leafletMarker.getLatLng();
          reverseGeocode(entry, pos.lat, pos.lng);
        });
      }
    });

    entry._leafletMap = map;
    entry.dataset.mapInit = 'true';
    wireLocationSearch(entry);

    requestAnimationFrame(() => map.invalidateSize());
  };

  const resetEntryMap = (entry) => {
    if (entry._leafletMap && entry._leafletMarker) {
      entry._leafletMap.removeLayer(entry._leafletMarker);
      entry._leafletMarker = null;
      entry._leafletMap.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
    }
    const box = entry.querySelector('.location-suggestions');
    if (box) { box.innerHTML = ''; box.classList.remove('show'); }
  };

  const makeWarehouseEntry = () => {
    const mapId = `warehouseMap${warehouseMapCounter}`;
    warehouseMapCounter += 1;

    const entry = document.createElement('div');
    entry.className = 'warehouse-entry';
    entry.innerHTML = `
      <button type="button" class="warehouse-remove-btn" aria-label="Remove warehouse">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none"><path d="M18 6L6 18M6 6L18 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </button>
      <div class="checkout-grid">
        <div class="form-group">
          <label>Warehouse Name</label>
          <input type="text" class="warehouse-name" placeholder="North Depot" required />
          <span class="field-error warehouse-name-error"></span>
        </div>
        <div class="form-group">
          <label>Location / Address</label>
          <div class="location-search-wrap">
            <input type="text" class="warehouse-location" placeholder="Search for a location…" autocomplete="off" required />
            <div class="location-suggestions"></div>
          </div>
          <span class="field-error warehouse-location-error"></span>
        </div>
      </div>
      <p class="warehouse-map-hint">Search above or click/drag the pin on the map to set the exact spot.</p>
      <div class="warehouse-map" id="${mapId}"></div>
      <input type="hidden" class="warehouse-lat" />
      <input type="hidden" class="warehouse-lng" />
    `;
    entry.querySelector('.warehouse-remove-btn').addEventListener('click', () => {
      if (entry._leafletMap) entry._leafletMap.remove();
      entry.remove();
      checkWarehouseForm();
    });
    return entry;
  };

  const checkWarehouseForm = () => {
    const entries = Array.from(warehouseList.querySelectorAll('.warehouse-entry'));
    const valid = entries.some((entry) => {
      const name = entry.querySelector('.warehouse-name').value.trim();
      const loc = entry.querySelector('.warehouse-location').value.trim();
      return name && loc;
    });
    document.getElementById('finishSetupBtn').disabled = !valid;
    return valid;
  };

  const wireWarehouseValidation = (entry) => {
    const nameInput = entry.querySelector('.warehouse-name');
    const locInput = entry.querySelector('.warehouse-location');
    const nameErr = entry.querySelector('.warehouse-name-error');
    const locErr = entry.querySelector('.warehouse-location-error');

    const validateEntry = () => {
      const name = nameInput.value.trim();
      const loc = locInput.value.trim();
      const nameGroup = nameInput.closest('.form-group');
      const locGroup = locInput.closest('.form-group');

      if (name) {
        nameErr.textContent = '';
        nameErr.classList.remove('show');
        nameGroup?.classList.remove('input-error');
      } else {
        nameErr.textContent = 'Warehouse name is required';
        nameErr.classList.add('show');
        nameGroup?.classList.add('input-error');
      }

      if (loc) {
        locErr.textContent = '';
        locErr.classList.remove('show');
        locGroup?.classList.remove('input-error');
      } else {
        locErr.textContent = 'Location is required';
        locErr.classList.add('show');
        locGroup?.classList.add('input-error');
      }

      checkWarehouseForm();
    };

    nameInput.addEventListener('input', validateEntry);
    locInput.addEventListener('input', validateEntry);
  };

  addWarehouseBtn.addEventListener('click', () => {
    const entry = makeWarehouseEntry();
    warehouseList.appendChild(entry);
    ensureMapInitialized(entry);
    wireWarehouseValidation(entry);
  });

  warehouseForm.addEventListener('submit', (e) => {
    e.preventDefault();
    warehouseList.querySelectorAll('.warehouse-entry').forEach((entry) => {
      const nameInput = entry.querySelector('.warehouse-name');
      const locInput = entry.querySelector('.warehouse-location');
      const nameErr = entry.querySelector('.warehouse-name-error');
      const locErr = entry.querySelector('.warehouse-location-error');
      const name = nameInput.value.trim();
      const loc = locInput.value.trim();
      const nameGroup = nameInput.closest('.form-group');
      const locGroup = locInput.closest('.form-group');

      if (!name) {
        nameErr.textContent = 'Warehouse name is required';
        nameErr.classList.add('show');
        nameGroup?.classList.add('input-error');
      }
      if (!loc) {
        locErr.textContent = 'Location is required';
        locErr.classList.add('show');
        locGroup?.classList.add('input-error');
      }
    });
    if (!checkWarehouseForm()) return;

    processingTitle.textContent = 'Finishing your setup…';
    processingNote.textContent = 'Preparing your Fleet Sense workspace.';
    showStep(stepProcessing, 'warehouse');

    setTimeout(() => {
      successPlanLabel.textContent = `, ${document.getElementById('firstName').value.trim() || 'there'}!`;
      showStep(stepSuccess, 'done');
      requestAnimationFrame(() => {
        redirectBar.style.width = '100%';
      });
      redirectTimeout = setTimeout(() => {
        window.location.href = REDIRECT_URL;
      }, 3000);
    }, 1600);
  });

  continueBtn.addEventListener('click', () => {
    if (redirectTimeout) clearTimeout(redirectTimeout);
  });

});