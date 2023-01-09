/*
    The MIT License(MIT)
    Copyright(c), Tobey Peters, https://github.com/tobeypeters
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software
    and associated documentation files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*  Lefal.js
    Description:
        Legal text
*/
import styles from '../App.module.css';

export function Hyperlinks() {
    // This Site may contain links to other independent third-party Web sites ("Linked Sites"). These Linked Sites are provided solely as a convenience to our visitors. Such Linked Sites are not under Apple’s control, and Apple is not responsible for and does not endorse the content of such Linked Sites, including any information or materials contained on such Linked Sites. You will need to make your own independent judgment regarding your interaction with these Linked Sites.
    return (
        <div className={styles.legal}>
            <h1>Hyperlink Disclaimer :</h1>
            This Benjémon site contains hyperlinks to other independent third-party Web sites ("Linked Sites") not under the editorial control of Benjémon. These Linked Sites are not express or implied endorsements or approvals by Benjémon of any products, services or information available from these Linked Sites. You will need to make your own independent judgment regarding your interaction with these Linked Sites.
            <br /><br />
        </div>
    )
}

export function Informational() {
    return (
        <div className={styles.legal}>
            <h1>Informational Content Disclaimer :</h1>
            THE INFORMATION AND DOWNLOADABLE SOFTWARE PROVIDED ON THIS WEB SITE IS [“ARE”] PROVIDED “AS IS” AND ALL WARRANTIES, EXPRESS OR IMPLIED, ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, MERCHANTABILITY OF ANY COMPUTER PROGRAM OR SOFTWARE, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY OF INFORMATIONAL CONTENT, OR SYSTEM INTEGRATION, OR NON–INFRINGEMENT. THE MAXIMUM LIABILITY OF Benjémon FOR ANY INACCURATE INFORMATION OR SOFTWARE AND YOUR SOLE AND EXCLUSIVE REMEDY FOR ANY CAUSE WHATSOEVER SHALL BE LIMITED TO THE AMOUNT PAID BY YOU FOR THE INFORMATION RECEIVED (IF ANY). Benjémon IS NOT LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL, LOSS OF BUSINESS, LOSS OF PROFITS OR CONSEQUENTIAL DAMAGES, WHETHER BASED ON BREACH OF CONTRACT, BREACH OF WARRANTY, TORT, NEGLIGENCE, PRODUCT LIABILITY OR OTHERWISE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
        </div>
    )
}

export function Copyright() {
    return (
        <div className={styles.legal}>
            <h1>Copyright Disclaimer :</h1>
            All Pokémon images and game data are the property of, and registered trademarks of, the following companies:<br />
            <ul>
                <li>The Pokémon Company : International - <a href='http://www.pokemon.com' target='_blank' rel='noreferrer'>http://www.pokemon.com</a></li>
                <li>Nintendo of America, Inc - <a href='http://www.nintendo.com' target='_blank' rel='noreferrer'>http://www.nintendo.com</a></li>
            </ul>
            © 2023 Pokémon. © 1995–2023 Nintendo/Creatures Inc./GAME FREAK inc. Pokémon, Pokémon character names, Nintendo Switch, Nintendo 3DS, Nintendo DS, Wii, Wii U, and WiiWare are trademarks of Nintendo. Other trademarks are the property of their respective owners.<br /><br />
            Data is being pulled from pokeapi.co - <a href='http://www.pokeapi.co' target='_blank' rel='noreferrer'>http://www.pokeapi.co</a><br /><br />
            All other text, graphics, audio files, Java applets & scripts, downloadable software, and any other works on this web site are the copyrighted works of Benjémon. All Rights Reserved. Any unauthorized redistribution or reproduction of any copyrighted materials on this web site is strictly prohibited.<br /><br />
        </div>
    )
}

export function Privacy() {
    return (
        <div className={styles.legal}>
            <h1>Private Policy Disclaimer</h1>
            <ul>
                <li>Policy. This Privacy Policy covers Benjémon’s treatment of personal or personally identifiable information (“Personal Information”) that may be collected when you are on the Benjémon’s web site and when you use Benjémon’s services. This policy does not apply to the practices of companies that Benjémon does not own or control or to individuals that are not under Benjémon’s supervisory control.</li>
                <li>Collection and Use of Personal Information. Benjémon may collect personal information about you (the “Personal Information”) when you use certain services on the Benjémon web site or when you visit cookie–enabled web pages. Benjémon may also log your IP address when you use the Benjémon web site. Benjémon uses this Personal Information to fulfill requests for our services or products, to contact users regarding changes to our site or our business, and to customize the content that you might see on the Benjémon web site. Benjémon may also use “cookie” files to better serve your needs by creating a customized web site which fits your needs.</li>
                <li>Sharing and Disclosure of Personal Information. Benjémon will not sell or rent your Personal Information to any individual, business, or government entity. Benjémon will share your Personal Information with other entities should you request Benjémon to share such information, or if Benjémon is required to respond to court orders, subpoenas or other legal process.</li>
                <li>User Accounts. Benjémon allows users to set up personal accounts (the “User Information”) to shop in our online store or to participate in our online communities, such as our message boards. You have the ability to edit your User Information at any time, and may delete your account at your convenience. Under no condition will Benjémon share your User Information with another individual, business or government entity, unless Benjémon is required to respond to court orders, subpoenas or other legal process.</li>
                <li>Encryption. All user account pages are / will be protected with Secure Socket Layer (“SSL”) encryption. All user accounts must be accessed with usernames and passwords. You are advised not to share your username and password with any other person.</li>
                <li>Amendments. Benjémon reserves the right to amend this policy at any time. Benjémon will contact registered users by email, and shall also post a notice of changes on its web site, when and if the terms of this policy are amended.</li>
                <li>Contact. You may contact Benjémon directly by emailing privacy@email.com should you have any questions regarding this policy.</li>
            </ul>
        </div>
    )
}

export function Terms() {
    return (
        <div className={styles.legal}>
            <h1>Terms of Service :</h1>
            <ul>
                <li>Acceptance of Terms of Use. Benjémon provides its online services and web site to you, the User, subject to this Terms of Service Agreement (“TOS”). Benjémon reserves the right to alter the TOS at any time without notice to User. By using the Benjémon web site, located at the URL http://www.Benjémontechnology.com, User agrees to abide by this TOS.</li>
                <li>Online Services and Disclaimer of Warranty. The Benjémon web site provides online resources including, but not limited to, online information regarding Benjémon’s services and products. Any new services, resources or informational content added to the web site shall fall under the terms of this TOS. The online resources, informational content, and software on this web site is provided “AS IS”, AND ALL WARRANTIES, EXPRESS OR IMPLIED, ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, MERCHANTABILITY OF ANY COMPUTER PROGRAM OR SOFTWARE, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY OF INFORMATIONAL CONTENT, OR SYSTEM INTEGRATION, OR NON–INFRINGEMENT. Benjémon assumes no responsibility for any data loss or other loss suffered by any User of this web site. User is fully responsible for maintaining its computer equipment and Internet access to use the Benjémon web site.</li>
                <li>Registration [if applicable]. Certain areas of the Benjémon web site are provided solely to registered Users of the web site. Any user (the “User”) accessing the web site and registering for such services agrees to provide true and accurate information during the registration process. Benjémon reserves the right to terminate the access of such Users should Benjémon know, or have reasonable grounds to suspect, that a User has entered false or misleading information during the registration process. ALL REGISTERED USERS MUST BE OF LEGAL AGE TO REGISTER. Children under the age of 18 shall not be permitted to register unless under the strict supervision of a legal guardian. Benjémon reserves the right to require valid credit card information as proof of legal age. Benjémon maintains strict online Privacy Policy and will not sell or give your information to other parties.</li>
                <li>User account [if applicable]. Users will select a username and password upon completing the registration process. Users are fully responsible for maintaining the confidentiality of their username and password. User agrees to immediately notify Benjémon at Benjémon@email.com should User know, or have reasonable grounds to suspect, that the username and password have been compromised. Benjémon shall not be responsible for User’s failure to abide by this paragraph.</li>
                <li>Informational content supplied by User. User understands that all information, computer files, software, graphics, sound files, and text, whether publicly displayed by User on the Benjémon web site, or privately transmitted through the Benjémon web site, are the responsibility of the User from which such informational content has originated. User is fully responsible for any and all informational content that user uploads, posts, emails, or transmits using the Benjémon web site. Benjémon does not and cannot control the informational content Users transmit through the Benjémon web site. Under no circumstances shall Benjémon be held liable for User’s exposure to informational content that User deems offensive, indecent or objectionable. Under no circumstances shall Benjémon be held liable for any errors or omissions in any informational content transmitted by Users.</li>
                <li>User conduct. User agrees to not use the Benjémon web site to: (a) upload, post, or transmit any informational content that is unlawful, threatens another person or entity, defamatory, vulgar, obscene, libelous, invades the privacy of another, or is otherwise objectionable; (b) harm legal minors; (c) collect personal information on, “cyberstalk” or harass another User, or engage in conduct that negatively affects the online experience of another User; (d) impersonate another User, person, or entity, including any official or employee of Benjémon; (e) intentionally or unintentionally violate any local, state, or federal law, including violations of the Copyright Act; (f) upload, post or transmit any software or files that contain software viruses or other harmful computer code; (g) interfere with the operation of Benjémon’s web servers or other computers or Internet or network connections; (h) upload, post or transmit any informational content that is the copyrighted, patented or trademarked intellectual property of another, or the trade secret of or confidential information of another; (i) upload, post or transmit and unsolicited or unauthorized advertising, including “spam” or “junk mail.” Benjémon does not pre–screen uploaded, posted or transmitted content, but Benjémon reserves the right to inspect, edit and delete any content that Benjémon knows, or has reason to know, has violated this TOS. Benjémon reserves the right to immediately, and without notice, terminate the access or the account of any User found to have violated the provisions of this TOS. Benjémon may disclose any informational content User posts, uploads or transmits to the Benjémon web site, if such disclosure is necessary to enforce this TOS, to respond to claims of intellectual property infringement, to comply with legal process, or to protect the rights of Benjémon, the public, or other users.</li>
                <li>Content submitted by User. Benjémon does not claim ownership of any informational content submitted by User to the Benjémon web site. User grants Benjémon a non–exclusive, royalty free license to use, distribute, reproduce, modify, and publicly display any informational content submitted to the Benjémon web site. This license exists only so long as User allows its content to remain on the Benjémon web site and will terminate in the event that User removes such content.</li>
                <li>Indemnity. User agrees to indemnify and hold Benjémon, and its members, affiliates, officers, agents, co–branders or other partners, and employees, harmless from any claim or demand, including reasonable attorneys’ fees, made by any third party due to or arising out of content User submits, posts, transmits or makes available through the Service, User’s use of the Service, User’s connection to the Service, User’s violation of the TOS, or User’s violation of any rights of another.</li>
                <li>No resale. User agrees not to reproduce, copy, duplicate, or sell any portion of the Benjémon web site.</li>
                <li>Limits and modifications. Benjémon may establish without notice limits on the use of its web site, including the maximum number of times User may post to or participate in the online communities, or to the number of times User may access the Benjémon web site. Benjémon reserves the right to modify any and all portions of the Benjémon web site without notice. Under no circumstances shall Benjémon be liable to User or any other party for such limits or modifications.</li>
                <li>Termination of User account or access. Benjémon may, at its sole discretion, terminate the User’s access to the Benjémon web site or account with Benjémon for any reason. Under no circumstances shall Benjémon be liable to User or any other party for such termination.</li>
                <li>Third party advertisers. Benjémon may allow third party advertisers to advertise on the Benjémon web site. Benjémon takes no responsibility for User’s dealings with, including any online or other purchases from, any third party advertisers. Benjémon shall not be liable for any loss or damage incurred by User in its dealings with third party advertisers.</li>
                <li>Hyperlink policy. The Benjémon site may contain hyperlinks to other Internet sites not under the editorial control of Benjémon. These hyperlinks are not express or implied endorsements or approvals by Benjémon of any products, services or information available from these sites.</li>
                <li>Benjémon’s intellectual property rights. User agrees not to distribute, license, or create derivative works from any of Benjémon’s copyrighted or trademarked material, including graphic files and software, available on the Benjémon web site.</li>
                <li>No warranties. THE INFORMATION AND DOWNLOADABLE SOFTWARE PROVIDED ON THIS WEB SITE IS PROVIDED “AS IS” AND ALL WARRANTIES, EXPRESS OR IMPLIED, ARE DISCLAIMED, INCLUDING, BUT NOT LIMITED TO, ANY IMPLIED WARRANTIES OF MERCHANTABILITY, MERCHANTABILITY OF ANY COMPUTER PROGRAM OR SOFTWARE, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY OF INFORMATIONAL CONTENT, OR SYSTEM INTEGRATION, OR NON–INFRINGEMENT.</li>
                <li>Limitation of liability. Benjémon’S MAXIMUM LIABILITY FOR ANY INACCURATE INFORMATION OR SOFTWARE AND YOUR SOLE AND EXCLUSIVE REMEDY FOR ANY CAUSE WHATSOEVER, SHALL BE LIMITED TO THE AMOUNT PAID BY YOU FOR THE INFORMATION RECEIVED (IF ANY). Benjémon IS NOT LIABLE FOR ANY INDIRECT, SPECIAL, INCIDENTAL, LOSS OF BUSINESS, LOSS OF PROFITS OR CONSEQUENTIAL DAMAGES, WHETHER BASED ON BREACH OF CONTRACT, BREACH OF WARRANTY, TORT, NEGLIGENCE, PRODUCT LIABILITY OR OTHERWISE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF CERTAIN WARRANTIES OR THE LIMITATION OR EXCLUSION OF LIABILITY FOR INCIDENTAL OR CONSEQUENTIAL DAMAGES. ACCORDINGLY, SOME OF THE LIMITATIONS OF THIS PARAGRAPH MAY NOT APPLY TO USER.</li>
                <li>Notice. Notices may be posted to the Benjémon web site or emailed to User using the email address User submitted during the registration process.</li>
                <li>General. This TOS constitutes the entire agreement between User and Benjémon and governs User’s use of the Benjémon web site. This TOS shall be governed by the laws of the State of Indiana. User agrees to submit to the personal and exclusive jurisdiction of the courts located within the county of Allen in the State of Indiana. The failure of Benjémon to exercise or enforce any right or provision of the TOS shall not constitute a waiver of such right or provision. If any provision of this TOS is found by a court of competent jurisdiction to be invalid, the parties nevertheless agree that the court should endeavor to give effect to the parties’ intentions as reflected in the provision, and the other provisions of the TOS remain in full force and effect. Any claim arising under the terms of this TOS must be brought within one (1) year after such claim or cause of action arose or be forever barred.</li>
                <li>Violations. Please report any known or suspected violations of the Terms of Use, including any suspected copyright or trademark violations, to copyright@email.com.</li>
            </ul>
        </div>
    )
}

export function Rights() {
    //https://en.wikipedia.org/wiki/All_rights_reserved
    return (
        <div>
            <div>
                All rights reserved &reg;
            </div>
        </div>
    )
}